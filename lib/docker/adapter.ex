defmodule Docker.Adapter do
  @moduledoc """
  An `Adapter` is a behaviour for specific versions of the Docker Engine API.
  It defines the common interface between all Docker Engine API versions.
  """

  alias Docker.{
    Exception,
    NotFound
  }

  alias Docker.{
    Config,
    Container,
    Event,
    # Plugin,
    Secret,
    Volume
  }

  # Docker.Config

  @type list_configs_opts :: %{
          optional(:id) => [String.t()],
          optional(:label) => [String.t()],
          optional(:name) => [String.t()]
        }

  # @type list_plugins_opts :: %{
  #         optional(:capability) => [String.t()],
  #         optional(:enabled) => boolean
  #       }

  # @callback list_plugins(list_plugins_opts()) :: {:ok, [Plugin.t()]} | {:error, Exception.t()}

  # @type plugin_privilege :: %{name: String.t(), description: String.t(), value: String.t()}

  # @callback get_plugin_privileges(String.t()) ::
  #             {:ok, plugin_privilege} | {:error, Exception.t() | NotFound.t()}
  @callback list_configs(list_configs_opts) ::
              {:ok, [Config.t()]} | {:error, Exception.t()}

  @callback create_config(String.t(), binary, map, map) ::
              {:ok, String.t()} | {:error, Exception.t()}

  @callback inspect_config(String.t()) ::
              {:ok, Config.t()} | {:error, Exception.t() | NotFound.t()}

  @callback remove_config(String.t()) ::
              :ok | {:error, Exception.t() | NotFound.t()}

  # Docker.Container

  @type prune_containers_opts :: %{
          optional(:label) => [String.t()]
        }

  @callback prune_containers(prune_containers_opts) :: {:ok, [Container.id()]} | {:error, term}

  # Docker.Event

  @type stream_events_opts :: %{
          optional(:since) => pos_integer,
          optional(:until) => pos_integer,
          optional(:resource) => [String.t() | atom],
          optional(:type) => [String.t() | atom],
          optional(:heir) => term
        }

  @callback stream_events(stream_events_opts) :: {:ok, Docker.EventStream.t()} | {:error, term}

  @type list_events_opts :: %{
          optional(:since) => pos_integer(),
          optional(:until) => pos_integer(),
          optional(:resource) => [String.t() | atom],
          optional(:type) => [String.t() | atom]
        }

  @callback list_events(list_events_opts) :: {:ok, [Event.t()]} | {:error, Exception.t()}

  # Docker.Plugin

  # @type list_plugins_opts :: %{
  #         optional(:capability) => [String.t()],
  #         optional(:enabled) => boolean
  #       }

  # @callback list_plugins(list_plugins_opts()) :: {:ok, [Plugin.t()]} | {:error, Exception.t()}

  # @type plugin_privilege :: %{name: String.t(), description: String.t(), value: String.t()}

  # @callback get_plugin_privileges(String.t()) ::
  #             {:ok, plugin_privilege} | {:error, Exception.t() | NotFound.t()}

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

  # Docker.System

  @type username_auth :: %{
          username: String.t(),
          password: String.t(),
          server: String.t()
        }

  @type email_auth :: %{
          email: String.t(),
          password: String.t(),
          server: String.t()
        }

  @callback authenticate(username_auth | email_auth) ::
              {:ok, String.t()} | {:error, Exception.t()}

  @callback get_version() :: term

  @callback ping() :: boolean

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
