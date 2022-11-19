defmodule Docker.Application do
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      Docker.DynamicSupervisor
    ]

    opts = [strategy: :one_for_one, name: Docker.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
