defmodule R8yV4Web.PageHTML do
  @moduledoc """
  This module contains pages rendered by PageController.

  See the `page_html` directory for all templates available.
  """
  use R8yV4Web, :html

  embed_templates "page_html/*"
end
