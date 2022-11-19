defmodule Docker.DynamicSupervisor do
  @moduledoc false

  use DynamicSupervisor

  @doc false
  def start_link(init_arg) do
    DynamicSupervisor.start_link(__MODULE__, init_arg, name: __MODULE__)
  end

  @doc false
  @impl DynamicSupervisor
  def init(_init_arg) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end

  @doc false
  def start_child(spec) do
    DynamicSupervisor.start_child(__MODULE__, spec)
  end

  @doc false
  def terminate_child(pid) do
    DynamicSupervisor.terminate_child(__MODULE__, pid)
  end
end
