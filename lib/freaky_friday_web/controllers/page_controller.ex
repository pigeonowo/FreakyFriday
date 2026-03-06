defmodule FreakyFridayWeb.PageController do
  use FreakyFridayWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end
