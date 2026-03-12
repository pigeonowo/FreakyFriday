defmodule FreakyFriday.Song do
  defstruct [:name, :album, :artists, :img_url]

  def new(name, album, artists, img_url) do
    %__MODULE__{name: name, album: album, artists: artists, img_url: img_url}
  end

  def title(%__MODULE__{name: title}) do
    case title do
      nil -> "Unknown"
      _ -> title
    end
  end

  def artists_text(%__MODULE__{artists: artists}) do
    case artists do
      nil -> "Unknown"
      _ -> Enum.join(artists, ", ")
    end
  end

  def image_url(%__MODULE__{img_url: img}) do
    case img do
      nil -> "/images/logo.svg"
      _ -> img
    end
  end
end
