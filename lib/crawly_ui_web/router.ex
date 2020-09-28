defmodule CrawlyUIWeb.Router do
  use CrawlyUIWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :put_root_layout, {CrawlyUIWeb.LayoutView, :root}
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", CrawlyUIWeb do
    pipe_through :browser

    live "/", JobLive, :index
    live "/all", JobLive, :show

    live "/spider", SpiderLive, :spider

    live "/schedule", ScheduleLive, :pick_node
    live "/schedule/spider", ScheduleLive, :pick_spider

    live "/jobs/:job_id/items", ItemLive, :index
    live "/jobs/:job_id/items/:id", ItemLive, :show
  end
end
