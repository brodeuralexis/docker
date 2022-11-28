defmodule Docker.DefaultAdapter do
  @moduledoc """
  An `Adapter` targeting the 1.41 version of the Docker daemon.
  """

  require Docker.Utilities
  import Docker.Utilities

  alias Docker.{
    Client,
    Config,
    Container,
    Image,
    Secret,
    Volume
  }

  @behaviour Docker.Adapter

  # The Docker.Client to use.
  @client Application.compile_env(:docker, :client, Docker.Client)
  @version "v1.41"

  # Docker.Config

  @doc false
  @impl true
  def list_configs(opts) do
    path = [@version, "configs"]
    query = %{filters: Jason.encode!(opts)}

    with {:ok, body} <- Client.request(:get, path, query: query) do
      {:ok, Enum.map(body, &map_config/1)}
    end
  end

  @doc false
  @impl true
  def create_config(name, value, labels, templating) do
    path = [@version, "configs", "create"]

    headers = [
      {"Content-Type", "application/json"}
    ]

    body = %{
      "Name" => name,
      "Data" => Base.encode64(value),
      "Labels" => labels,
      "Templating" => templating
    }

    with {:ok, body} <- Client.request(:post, path, headers: headers, body: body) do
      {:ok, body["ID"]}
    end
  end

  @doc false
  @impl true
  def inspect_config(id) do
    path = [@version, "configs", id]

    with {:ok, body} <- Client.request(:get, path, not_found: true) do
      {:ok, map_config(body)}
    end
  end

  @doc false
  @impl true
  def remove_config(id) do
    path = [@version, "configs", id]

    with {:ok, _body} <- Client.request(:delete, path, not_found: true) do
      :ok
    end
  end

  def map_config(attrs) do
    %Config{
      attrs: attrs,
      id: attrs["ID"],
      name: attrs["Spec"]["Name"]
    }
  end

  # Docker.Container

  @doc false
  @impl true
  def list_containers(_opts) do
    path = [@version, "containers", "json"]
    query = %{}

    with {:ok, body} <- @client.request(:get, path, query: query) do
      {:ok, Enum.map(body, &map_list_container/1)}
    end
  end

  defp map_list_container(attrs) do
    %Container{
      attrs: attrs,
      id: attrs["Id"],
      image: attrs["ImageID"],
      labels: attrs["Labels"],
      name: List.first(attrs["Names"]),
      short_id: String.slice(attrs["Id"], 0, 12),
      # FIXME: Validate status in order not to leak atoms
      status: map_container_status(attrs["State"])
    }
  end

  @doc false
  @impl true
  def inspect_container(id_or_name) do
    path = [@version, "containers", id_or_name, "json"]

    with {:ok, attrs} <- @client.request(:get, path) do
      {:ok, map_inspect_container(attrs)}
    end
  end

  defp map_inspect_container(attrs) do
    %Container{
      attrs: attrs,
      id: attrs["Id"],
      image: attrs["Image"],
      labels: attrs["Config"]["Labels"],
      name: attrs["Name"],
      short_id: String.slice(attrs["Id"], 0, 12),
      status: map_container_status(attrs["State"]["Status"])
    }
  end

  defp map_container_status("created"), do: :created
  defp map_container_status("restarting"), do: :restarting
  defp map_container_status("running"), do: :running
  defp map_container_status("removing"), do: :removing
  defp map_container_status("paused"), do: :paused
  defp map_container_status("exited"), do: :exited
  defp map_container_status("dead"), do: :dead

  @doc false
  @impl true
  def prune_containers(opts) do
    path = [@version, "containers", "prune"]
    # transfer(%{}, "label", opts, :label)
    filters = %{}
    query = %{filters: Jason.encode!(filters)}

    with {:ok, %{"ContainersDeleted" => container_ids}} <-
           @client.request(:post, path, query: query) do
      {:ok, if(container_ids, do: container_ids, else: [])}
    end
  end

  # Docker.Event

  @doc false
  @impl true
  def stream_events(opts) do
    owner = Access.get(opts, :heir, self())
    filters = prepare_list_events_filters(opts)
    query = %{since: opts[:since], until: opts[:until], filters: Jason.encode!(filters)}

    with {:ok, pid} <-
           Docker.DynamicSupervisor.start_child(
             Docker.DefaultAdapter.EventStream.child_spec(query: query, heir: owner)
           ) do
      {:ok, %Docker.DefaultAdapter.EventStream{pid: pid}}
    else
      :ignore ->
        raise RuntimeError, "expected process to not be ignored"

      {:error, {:already_started, pid}} ->
        raise RuntimeError, "expected process to not already be started: #{inspect(pid)}"

      {:error, :max_children} ->
        raise RuntimeError, "expected :max_children to be :infinite"

      {:error, reason} ->
        {:error, reason}
    end
  end

  @doc false
  @impl true
  def list_events(opts) do
    opts =
      opts
      |> Map.new()
      |> Map.put(:heir, self())

    with {:ok, stream} <- stream_events(opts),
         {:ok, events} <- do_list_events(stream) do
      {:ok, Enum.reverse(events)}
    end
  end

  @spec do_list_events(term, list) :: {:ok, list} | {:error, term}
  defp do_list_events(stream, acc \\ []) do
    receive do
      {:docker_events, %Docker.Event{} = event} ->
        do_list_events(stream, [event | acc])

      {:docker_events, :done} ->
        {:ok, acc}
    end
  end

  defp prepare_list_events_filters(opts) do
    filters = %{}

    filters =
      case Access.fetch(opts, :resource) do
        {:ok, resources} ->
          Map.put(filters, :type, resources)

        :error ->
          filters
      end

    filters =
      case Access.fetch(opts, :type) do
        {:ok, types} ->
          Map.put(filters, :event, types)

        :error ->
          filters
      end

    filters
  end

  def map_event(attrs) do
    %Docker.Event{
      attrs: attrs,
      resource: attrs["Type"],
      event: attrs["Event"],
      id: attrs["Actor"]["ID"]
    }
  end

  # Docker.Image

  @doc false
  @impl true
  def list_images(_opts) do
    path = [@version, "images", "json"]
    query = %{}

    with {:ok, body} <- @client.request(:get, path, query: query) do
      {:ok, Enum.map(body, &map_list_image/1)}
    end
  end

  defp map_list_image(attrs) do
    %Image{
      attrs: attrs,
      id: attrs["Id"],
      labels: attrs["Labels"] || %{},
      short_id: String.slice(attrs["Id"], 7, 12),
      tags: attrs["RepoTags"]
    }
  end

  @doc false
  @impl true
  def inspect_image(id) do
    path = [@version, "images", id, "json"]

    with {:ok, attrs} <- @client.request(:get, path, not_found: true) do
      {:ok, map_inspect_image(attrs)}
    end
  end

  defp map_inspect_image(attrs) do
    %Image{
      attrs: attrs,
      id: attrs["Id"],
      labels: attrs["Config"]["Labels"] || %{},
      short_id: String.slice(attrs["Id"], 7, 12),
      tags: attrs["RepoTags"]
    }
  end

  # Docker.Secret

  @doc false
  @impl true
  def list_secrets(opts) do
    path = [@version, "secrets"]
    query = %{filters: Jason.encode!(opts)}

    with {:ok, body} <- Client.request(:get, path, query: query) do
      {:ok, Enum.map(body, &map_secret/1)}
    end
  end

  @doc false
  @impl true
  def create_secret(name, data, opts) do
    path = [@version, "secrets", "create"]
    headers = [{"Content-Type", "application/json"}]

    body = %{
      "Name" => name,
      "Data" => Base.encode64(data),
      "Labels" => Access.get(opts, :labels, %{})
    }

    body =
      case Access.fetch(opts, :driver) do
        {:ok, driver} ->
          Map.put(body, "Driver", %{
            "Name" => driver,
            "Options" => Access.get(opts, :driver_opts, %{})
          })

        :error ->
          body
      end

    with {:ok, %{"ID" => id}} <- Client.request(:post, path, headers: headers, body: body) do
      {:ok, id}
    end
  end

  @doc false
  @impl true
  def inspect_secret(id) do
    path = [@version, "secrets", id]

    with {:ok, body} <- Client.request(:get, path, not_found: true) do
      {:ok, map_secret(body)}
    end
  end

  @doc false
  @impl true
  def remove_secret(id) do
    path = [@version, "secrets", id]

    with {:ok, _body} <- Client.request(:delete, path, not_found: true) do
      :ok
    end
  end

  @doc false
  @impl true
  def update_secret(secret, opts) do
    path = [@version, "secrets", secret.id, "update"]
    headers = [{"Content-Type", "application/json"}]
    query = %{version: secret.version}

    body = %{
      "Name" => secret.name,
      "Labels" => Access.get(opts, :labels, %{}),
      "Data" => "",
      "Driver" => secret.attrs["Spec"]["Driver"]
    }

    with {:ok, _body} <-
           Client.request(:post, path, headers: headers, query: query, body: body, not_found: true) do
      {:ok, secret.id}
    end
  end

  def map_secret(attrs) do
    %Secret{
      attrs: attrs,
      id: attrs["ID"],
      short_id: String.slice(attrs["ID"], 0, 12),
      name: attrs["Spec"]["Name"],
      version: attrs["Version"]["Index"]
    }
  end

  # Docker.System

  @doc false
  @impl true
  def authenticate(params) do
    path = [@version, "auth"]
    headers = [{"Content-Type", "application/json"}]

    with {:ok, token} <-
           @client.request(:post, path, headers: headers, body: params) do
      {:ok, token}
    end
  end

  @doc false
  @impl true
  def get_version() do
    path = [@version, "version"]

    with {:ok, %{"Version" => version}} <- @client.request(:get, path) do
      {:ok, version}
    end
  end

  @doc false
  @impl true
  def ping() do
    path = [@version, "_ping"]

    case @client.request(:get, path) do
      {:ok, _} -> true
      {:error, _} -> false
    end
  end

  # Docker.Volume

  @doc false
  @impl true
  def list_volumes(opts) do
    path = [@version, "volumes"]
    query = %{filters: Jason.encode!(opts)}

    with {:ok, %{"Volumes" => volumes}} <- Client.request(:get, path, query: query) do
      {:ok, Enum.map(volumes, &map_volume/1)}
    end
  end

  @doc false
  @impl true
  def create_volume(name, opts) do
    path = [@version, "volumes", "create"]

    headers = [
      {"Content-Type", "application/json"}
    ]

    body = %{
      "Name" => name,
      "Driver" => Access.get(opts, :driver, "local"),
      "DriverOpts" => Access.get(opts, :driver_opts, %{}),
      "Labels" => Access.get(opts, :labels, %{})
    }

    with {:ok, body} <- Client.request(:post, path, headers: headers, body: body) do
      {:ok, body["Name"]}
    end
  end

  @doc false
  @impl true
  def inspect_volume(name) do
    path = [@version, "volumes", name]

    with {:ok, body} <- Client.request(:get, path, not_found: true) do
      {:ok, map_volume(body)}
    end
  end

  @doc false
  @impl true
  def remove_volume(name) do
    path = [@version, "volumes", name]

    with {:ok, _body} <- Client.request(:delete, path, not_found: true) do
      :ok
    end
  end

  def map_volume(attrs) do
    %Volume{
      attrs: attrs,
      name: attrs["Name"]
    }
  end
end
