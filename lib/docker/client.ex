defmodule Docker.Client do
  @moduledoc """
  A generic client implementation backed by the `:hackney` library.
  """

  require Logger

  alias Docker.Exception
  alias Docker.NotFound

  @host Application.compile_env(:docker, :host, "http+unix:///var/run/docker.sock")

  @type method :: :get | :post | :put | :patch | :delete | :head | :options

  @type path :: String.t() | [String.t()]

  @type query :: keyword | map

  @type headers :: [{String.t(), String.t()}]

  @type body :: any

  @type request_opts ::
          Enumerable.t(
            {:query, query}
            | {:body, body}
            | {:headers, headers}
          )

  @doc """
  Sends a request to Docker, and receive a response, returning the body in an
  `:ok` tuple in case of success, or the exception in an `:error` tuple in case
  of failure.
  """
  @spec request(method, path) :: {:ok, any} | {:error, Exception.t() | NotFound.t()}
  @spec request(method, path, request_opts) :: {:ok, any} | {:error, Exception.t() | NotFound.t()}
  def request(method, path, opts \\ []) do
    {not_found, opts} = Keyword.pop(opts, :not_found, false)
    {headers, opts} = Keyword.pop(opts, :headers, [])
    {query, opts} = Keyword.pop(opts, :query, nil)
    {body, opts} = Keyword.pop(opts, :body, <<>>)

    url =
      path
      |> build_uri(query)
      |> URI.to_string()

    body =
      if header?(headers, "Content-Type", "application/json") do
        Jason.encode!(body)
      else
        body
      end

    with {:ok, status, headers, ref} <- :hackney.request(method, url, headers, body, opts),
         {:ok, body} <- :hackney.body(ref) do
      cond do
        status in 200..299 ->
          {:ok,
           if header?(headers, "Content-Type", "application/json") do
             Jason.decode!(body)
           else
             body
           end}

        status == 404 and header?(headers, "Content-Type", "application/json") and not_found ->
          %{"message" => msg} = Jason.decode!(body)

          {:error, NotFound.exception(msg)}

        status in 400..599 and header?(headers, "Content-Type", "application/json") ->
          %{"message" => msg} = Jason.decode!(body)

          {:error, Exception.exception(msg)}

        true ->
          Logger.alert("received a weird response from Docker",
            method: method,
            url: url,
            status: status,
            headers: headers,
            body: body
          )

          raise RuntimeError, "received a weird response from Docker"
      end
    end
  end

  @doc """
  Sends an asynchronous request to Docker, and receive the response.
  """
  @spec async_request(method, path) :: {:ok, reference} | {:error, Exception.t() | NotFound.t()}
  @spec async_request(method, path, request_opts) ::
          {:ok, reference} | {:error, Exception.t() | NotFound.t()}
  def async_request(method, path, opts \\ []) do
    {not_found, opts} = Keyword.pop(opts, :not_found, false)
    {headers, opts} = Keyword.pop(opts, :headers, [])
    {query, opts} = Keyword.pop(opts, :query, nil)
    {body, opts} = Keyword.pop(opts, :body, <<>>)

    url =
      path
      |> build_uri(query)
      |> URI.to_string()

    body =
      if header?(headers, "Content-Type", "application/json") do
        Jason.encode!(body)
      else
        body
      end

    with {:ok, ref} <- :hackney.request(method, url, headers, body, [:async | opts]) do
      status =
        receive do
          {:hackney_response, ^ref, {:status, status, _reason}} ->
            status
        end

      headers =
        receive do
          {:hackney_response, ^ref, {:headers, headers, _reason}} ->
            headers
        end

      cond do
        status in 200..299 ->
          {:ok, ref}

        status == 404 and header?(headers, "Content-Type", "application/json") and not_found ->
          :hackney.stop_async(ref)

          with {:ok, body} <- :hackney.body(ref) do
            %{"message" => msg} = Jason.decode!(body)

            {:error, NotFound.exception(msg)}
          end

        status in 400..599 and header?(headers, "Content-Type", "application/json") ->
          :hackney.stop_async(ref)

          with {:ok, body} <- :hackney.body(ref) do
            %{"message" => msg} = Jason.decode!(body)

            {:error, Exception.exception(msg)}
          end

        true ->
          Logger.alert("received a weird response from Docker",
            method: method,
            url: url,
            status: status,
            headers: headers,
            body: body
          )

          raise RuntimeError, "received a weird response from Docker"
      end
    end
  end

  @doc """
  Cancels the request.
  """
  @spec cancel(reference) :: term
  def cancel(ref) do
    :hackney.cancel_request(ref)
  end

  defp build_uri(path, query) when is_map(query) do
    uri = build_uri(path, nil)

    %{uri | query: URI.encode_query(query)}
  end

  defp build_uri(path, nil) do
    host = normalize_host(@host)
    path = normalize_path(path)

    host
    |> String.trim_trailing("/")
    |> Kernel.<>(path)
    |> URI.new!()
  end

  defp normalize_host(host) do
    case host do
      "http+unix://" <> rest ->
        "http+unix://" <> URI.encode_www_form(rest)

      "unix+http://" <> rest ->
        "http+unix://" <> URI.encode_www_form(rest)

      "http://" <> rest ->
        "http://" <> rest

      _ ->
        raise ArgumentError, "invalid host: #{inspect(host)}"
    end
  end

  defp normalize_path(path) when is_list(path) do
    segments =
      path
      |> Stream.map(&normalize_path/1)
      |> Enum.join("/")

    "/" <> segments
  end

  defp normalize_path(path) when is_binary(path) do
    URI.encode(path)
  end

  defp header?(headers, key, value) do
    key = String.downcase(key)
    value = String.downcase(value)

    Enum.any?(headers, fn {key_, value_} ->
      key == String.downcase(key_) and value == String.downcase(value_)
    end)
  end
end
