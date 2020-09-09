defmodule CrawlyUIWeb.JobController do
  use CrawlyUIWeb, :controller
  import Phoenix.LiveView.Controller

  alias CrawlyUI.Manager

  def index(conn, _params) do
    jobs = Manager.list_jobs()
    live_render(conn, CrawlyUIWeb.JobLive, session: %{"jobs" => jobs})
  end

  def pick_node(conn, _params) do
    live_render(conn, CrawlyUIWeb.ScheduleLive, session: %{"nodes" => Node.list()})
  end

  def pick_spider(conn, %{"node" => node}) do
    live_render(conn, CrawlyUIWeb.ScheduleLive, session: %{"node" => node, "error" => nil})
  end
end
