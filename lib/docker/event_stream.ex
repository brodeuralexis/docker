defprotocol Docker.EventStream do
  @moduledoc """
  A protocol for a stream of events.
  """

  alias Docker.Exception

  @type t :: term

  @doc """
  Makes the process `pid` the new owner of the stream as well as the one to
  receive events from the stream.
  """
  @spec give_away(t, pid) :: :ok
  def give_away(stream, new_owner)

  @doc """
  Closes the stream early.
  """
  @spec close(t) :: :ok | {:error, Exception.t()}
  def close(stream)
end
