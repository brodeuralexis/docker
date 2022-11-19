defmodule Docker.Adapters.DefaultAdapter do
  @moduledoc """
  The default `Adapter` for the Docker daemon.

  This will default to delegating to the latest Docker daemon `Adapter` that is
  implemented and working, but it may diverge in case problems arise with
  specific endpoints of the Docker daemon API.
  """

  alias Docker.Adapters.V1_41Adapter

  # Docker.Config

  defdelegate list_configs(opts), to: V1_41Adapter
  defdelegate create_config(name, value, labels, templating), to: V1_41Adapter
  defdelegate inspect_config(id), to: V1_41Adapter
  defdelegate remove_config(id), to: V1_41Adapter

  # Docker.Secret

  defdelegate list_secrets(opts), to: V1_41Adapter
  defdelegate create_secret(name, data, opts), to: V1_41Adapter
  defdelegate inspect_secret(id), to: V1_41Adapter
  defdelegate remove_secret(id), to: V1_41Adapter
  defdelegate update_secret(secret, opts), to: V1_41Adapter

  # Docker.Volume

  defdelegate list_volumes(opts), to: V1_41Adapter
  defdelegate create_volume(name, opts), to: V1_41Adapter
  defdelegate inspect_volume(name), to: V1_41Adapter
  defdelegate remove_volume(name), to: V1_41Adapter
end
