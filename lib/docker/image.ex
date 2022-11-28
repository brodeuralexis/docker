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

  require Docker.Utilities
  import Docker.Utilities

  alias Docker.{
    Exception,
    NotFound
  }

  @adapter Application.compile_env(:docker, :adapter, Docker.DefaultAdapter)

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

  @typedoc """
  The list of options that may be provided to the `list/1` function.
  """
  @type list_opts ::
          Enumerable.t(
            {:all, boolean}
            | {:dangling, boolean}
            | {:before, String.t() | [String.t()]}
            | {:label, String.t() | [String.t()]}
            | {:reference, String.t() | [String.t()]}
            | {:since, String.t() | [String.t()]}
          )

  @doc """
  Lists [images](`Docker.Image`).

  ## TODO: Options
  """
  @spec list() :: {:ok, [t]} | {:error, Exception.t()}
  @spec list(list_opts) :: {:ok, [t]} | {:error, Exception.t()}
  def list(_opts \\ []) do
    @adapter.list_images(%{})
  end

  @doc """
  Lists [images](`Docker.Image`).

  Unlike `list/1`, this function will *raise* if an error occurs, or return the
  list directly on success.

  For more information about usage and options, see `list/1`.
  """
  @spec list!() :: [t]
  @spec list!(list_opts) :: [t]
  def list!(opts \\ []) do
    case list(opts) do
      {:ok, images} ->
        images

      {:error, reason} ->
        raise reason
    end
  end

  @doc """
  Gets an [image](`Docker.Image`).
  """
  @spec get(String.t()) :: {:ok, t} | {:error, Exception.t() | NotFound.t()}
  def get(id) when is_binary(id) do
    @adapter.inspect_image(id)
  end

  @doc """
  Gets an [image](`Docker.Image`).

  Unlike `get/1`, this function will *raise* if an error occurs, or return the
  image directly on success.

  For more information about usage, see `get/1`.
  """
  @spec get!(String.t()) :: t
  def get!(id) when is_binary(id) do
    case get(id) do
      {:ok, image} ->
        image

      {:error, reason} ->
        raise reason
    end
  end
end
