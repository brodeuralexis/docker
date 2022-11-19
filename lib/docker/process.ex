defmodule Docker.Process do
  @moduledoc """
  A representation of a process running inside a container of the Docker daemon.

  TODO: More information
  """

  @typedoc """
  Representation of a process running inside a Docker daemon
  [container](`Docker.Container`).
  """
  @type t :: %__MODULE__{
          uid: String.t(),
          pid: String.t(),
          ppid: String.t(),
          c: String.t(),
          stime: String.t(),
          tty: String.t(),
          time: String.t(),
          cmd: String.t()
        }

  @enforce_keys [:uid, :pid, :ppid, :c, :stime, :tty, :time, :cmd]
  defstruct [:uid, :pid, :ppid, :c, :stime, :tty, :time, :cmd]
end
