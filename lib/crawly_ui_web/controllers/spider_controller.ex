defmodule CrawlyUIWeb.SpiderController do
  use CrawlyUIWeb, :controller

  def index(conn, _params) do
    render(conn, "index.html")
  end
end
