defmodule Docker.Adapters.V1_41Adapter do
  @moduledoc """
  An `Adapter` targeting the 1.41 version of the Docker daemon.
  """

  alias Docker.{
    Client,
    Config,
    Secret,
    Volume
  }

  @version "v1.41"

  @behaviour Docker.Adapters.Adapter

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

  defp map_config(attrs) do
    %Config{
      attrs: attrs,
      id: attrs["ID"],
      name: attrs["Spec"]["Name"]
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

  defp map_secret(attrs) do
    %Secret{
      attrs: attrs,
      id: attrs["ID"],
      short_id: String.slice(attrs["ID"], 0, 12),
      name: attrs["Spec"]["Name"],
      version: attrs["Version"]["Index"]
    }
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

  defp map_volume(attrs) do
    %Volume{
      attrs: attrs,
      name: attrs["Name"]
    }
  end
end
