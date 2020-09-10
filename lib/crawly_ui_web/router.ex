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

    get "/", JobController, :index

    get "/schedule", JobController, :pick_node

    get "/schedule/spider", JobController, :pick_spider
    get "/schedule/finish", JobController, :schedule

    get "/jobs/:job_id/items", ItemController, :index
    get "/jobs/:job_id/items/:id", ItemController, :show
  end
end
