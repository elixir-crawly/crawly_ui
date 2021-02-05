defmodule Cars do
  def start_crawl_autoria() do
    Crawly.Engine.start_spider(Cars.Autoria.Spider)
  end
end
