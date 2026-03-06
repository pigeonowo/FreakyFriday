defmodule FreakyFriday.Repo do
  use Ecto.Repo,
    otp_app: :freaky_friday,
    adapter: Ecto.Adapters.SQLite3
end
