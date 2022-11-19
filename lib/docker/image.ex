defmodule Docker.Image do
  @moduledoc """
  A representation of a Docker daemon image and a bunch of functions for dealing
  with images.

  TODO: More information

  ## Raw Representation

  Not all fields returned by the Docker daemon are provided on the
  `Docker.Image` data s tructure.  Only a subset of fields are supported to
  ensure compatibility between multiple versions.

  To access the raw representation, the `:attrs` field is available with the
  deserialized raw response from the Docker daemon.

  For images, the raw representation may change heavily depending of where the
  data came from.  The *List Images* and *Inspect Image* API return a different
  raw representation, the latter providing more information.

  To refresh the raw representation, the `reload/1` and `reload!/1` functions
  are availabl, and will ensure that the more detailed *Inspect Container*
  representation is used:
  ```elixir
  image = Docker.Image.reload!(image)
  ```
  """

  @typedoc """
  The ID of an [image](`Docker.Image`).
  """
  @type id :: String.t()

  @typedoc """
  Representation of a Docker daemon [image](`Docker.Image`).
  """
  @type t :: %__MODULE__{
          attrs: any,
          id: id,
          labels: %{String.t() => String.t()},
          short_id: String.t(),
          tags: [String.t()]
        }

  @derive {Inspect, only: [:id, :labels, :short_id, :tags]}
  @enforce_keys [:attrs, :id, :labels, :short_id, :tags]
  defstruct [:attrs, :id, :labels, :short_id, :tags]
end
