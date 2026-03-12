defmodule FreakyFriday do
  @moduledoc """
  FreakyFriday keeps the contexts that define your domain
  and business logic.

  Contexts are also responsible for managing your data, regardless
  if it comes from the database, an external API or others.
  """
  @spec gen_random_string() :: String.t()
  def gen_random_string() do
    for _ <- 0..16, into: "" do
      <<Enum.random(?A..?Z)>>
    end
  end
end
