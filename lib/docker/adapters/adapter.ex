defmodule Docker.Adapters.Adapter do
  @moduledoc """
  An `Adapter` is a behaviour for specific versions of the Docker Engine API.
  It defines the common interface between all Docker Engine API versions.
  """

  alias Docker.{
    Exception,
    NotFound
  }

  alias Docker.{Config, Secret, Volume}

  # Docker.Config

  @type list_configs_opts :: %{
          optional(:id) => [String.t()],
          optional(:label) => [String.t()],
          optional(:name) => [String.t()]
        }

  @callback list_configs(list_configs_opts) ::
              {:ok, [Config.t()]} | {:error, Exception.t()}

  @callback create_config(String.t(), binary, map, map) ::
              {:ok, String.t()} | {:error, Exception.t()}

  @callback inspect_config(String.t()) ::
              {:ok, Config.t()} | {:error, Exception.t() | NotFound.t()}

  @callback remove_config(String.t()) ::
              :ok | {:error, Exception.t() | NotFound.t()}

  # Docker.Secret

  @type list_secrets_opts :: %{
          optional(:id) => [String.t()],
          optional(:label) => [String.t()],
          optional(:name) => [String.t()]
        }

  @callback list_secrets(list_secrets_opts()) :: {:ok, [Secret.t()]} | {:error, Exception.t()}

  @type create_secret_opts :: %{
          optional(:labels) => map,
          optional(:driver) => String.t(),
          optional(:driver_opts) => map
        }

  @callback create_secret(String.t(), binary, create_secret_opts) ::
              {:ok, String.t()} | {:error, Exception.t()}

  @callback inspect_secret(String.t()) ::
              {:ok, Secret.t()} | {:error, Exception.t() | NotFound.t()}

  @callback remove_secret(String.t()) :: :ok | {:error, Exception.t() | NotFound.t()}

  @type update_secret_opts :: %{
          optional(:labels) => %{String.t() => String.t()}
        }

  @callback update_secret(Secret.t(), update_secret_opts) ::
              {:ok, String.t()} | {:error, Exception.t() | NotFound.t()}

  # Docker.Volume

  @type list_volumes_opts :: %{
          optional(:dangling) => [String.t()],
          optional(:driver) => [String.t()],
          optional(:label) => [String.t()],
          optional(:name) => [String.t()]
        }

  @callback list_volumes(list_volumes_opts()) :: {:ok, [Volume.t()]} | {:error, Exception.t()}

  @type create_volume_opts :: %{
          optional(:driver) => String.t(),
          optional(:driver_opts) => Enumerable.t(),
          optional(:labels) => [String.t()]
        }

  @callback create_volume(String.t(), create_volume_opts) ::
              {:ok, String.t()} | {:error, Exception.t()}

  @callback inspect_volume(String.t()) ::
              {:ok, Volume.t()} | {:error, Exception.t() | NotFound.t()}

  @type remove_volume_opts :: %{
          optional(:force) => boolean
        }

  @callback remove_volume(String.t()) :: :ok | {:error, Exception.t() | NotFound.t()}
end
