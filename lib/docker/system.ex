defmodule Docker.System do
  @moduledoc """
  A bunch of system related functions for the Docker daemon running on this
  node.
  """

  @adapter Application.compile_env(:docker, :adapter, Docker.DefaultAdapter)

  @typedoc """
  The params to provide to the `auth/1` function when authenticating using a
  username.
  """
  @type username_auth ::
          Enumerable.t(
            {:username, String.t()}
            | {:password, String.t()}
            | {:server, String.t()}
          )

  @typedoc """
  The params to provide to the `auth/1` function when authenticating using an
  email address.
  """
  @type email_auth ::
          Enumerable.t(
            {:email, String.t()}
            | {:password, String.t()}
            | {:server, String.t()}
          )

  @doc """
  Authenticates the user to a registry.

  # Options

    - `:username` (required) takes a username to use for authentication, or
        `:email` (required) takes an email address to use for authenticaation.
    - `:password` (required) takes the password to use for authentication.
    - `:server` (defaults to `"https://index.docker.io/v1/"`) takes the registry
      to use for authentication.
  """
  @spec authenticate(username_auth | email_auth) :: {:ok, String.t()} | {:error, Exception.t()}
  def authenticate(params) do
    case {Access.fetch(params, :username), Access.fetch(params, :email)} do
      {{:ok, _username}, {:ok, _email}} ->
        raise ArgumentError, "cannot provide both the :username and :email option"

      {:error, :error} ->
        raise ArgumentError, "expected either of :username or :email option to be defined"

      _ ->
        nil
    end

    params =
      params
      |> Map.new()
      |> Map.take([:username, :email, :password, :server])
      |> Map.put_new(:server, "https://index.docker.io/v1/")

    @adapter.authenticate(params)
  end

  @doc """
  Authenticates the user to a registry.

  Unlike `authenticate/1`, this function will *raise* if an error occurs, or
  return the authentication token directly on success.

  For more information about usage, see `authenticate/1`.
  """
  @spec authenticate!(username_auth | email_auth) :: String.t()
  def authenticate!(params) do
    case authenticate(params) do
      {:ok, token} ->
        token

      {:error, reason} ->
        raise reason
    end
  end

  @doc """
  Returns the version of the Docker daemon.
  """
  @spec version() :: {:ok, String.t()} | {:error, Exception.t()}
  def version() do
    @adapter.get_version()
  end

  @doc """
  Returns teh version of the Docker daemon.

  Unlike `version/0`, this function will *raise* if an error occurs, or return
  the version directly on success.

  For more information about usage, see `version/0`.
  """
  @spec version!() :: String.t()
  def version!() do
    case version() do
      {:ok, version} ->
        version

      {:error, reason} ->
        raise reason
    end
  end

  @doc """
  Pings the server and returns if it is accessible and in working order.
  """
  @spec ping() :: boolean
  def ping() do
    @adapter.ping()
  end
end
