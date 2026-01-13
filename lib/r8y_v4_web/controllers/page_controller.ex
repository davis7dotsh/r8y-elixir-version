defmodule R8yV4Web.PageController do
  use R8yV4Web, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end
