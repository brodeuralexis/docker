defmodule Docker.Exception do
  @moduledoc """
  A general purpose exception type that may be returned by an error tuple or
  raised when calling the Docker SDK.
  """

  @typedoc """
  Representation of a `Docker.Exception`.
  """
  @type t :: %__MODULE__{
          message: String.t()
        }

  defexception [:message]
end

defmodule Docker.NotFound do
  @moduledoc """
  A specialized exception type that may be returned by an error tuple or raised
  when calling a Docker daemon endpoint that may return a 404 indicating that a
  resource does not exist.
  """

  @typedoc """
  Representation of a `Docker.NotFound` exception.
  """
  @type t :: %__MODULE__{
          message: String.t()
        }

  defexception [:message]
end

defmodule Docker.NotLoaded do
  @moduledoc """
  Although not an exception per say, it represents a relationship that has not
  yet been loaded by the client.
  """

  @enforce_keys []
  defstruct []
end
