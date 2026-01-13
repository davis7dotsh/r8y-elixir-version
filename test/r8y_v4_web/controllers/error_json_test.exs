defmodule R8yV4Web.ErrorJSONTest do
  use R8yV4Web.ConnCase, async: true

  test "renders 404" do
    assert R8yV4Web.ErrorJSON.render("404.json", %{}) == %{errors: %{detail: "Not Found"}}
  end

  test "renders 500" do
    assert R8yV4Web.ErrorJSON.render("500.json", %{}) ==
             %{errors: %{detail: "Internal Server Error"}}
  end
end
