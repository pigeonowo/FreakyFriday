defmodule FreakyFriday.Participant do
  @max_skips 2
  defstruct name: "", id: "", skips: @max_skips

  def new(name, id) do
    %__MODULE__{name: name, id: id, skips: @max_skips}
  end
end
