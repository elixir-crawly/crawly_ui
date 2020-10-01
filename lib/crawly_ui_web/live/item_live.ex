defmodule CrawlyUIWeb.ItemLive do
  use Phoenix.LiveView

  alias CrawlyUI.Manager

  def render(%{template: template} = assigns) do
    CrawlyUIWeb.ItemView.render(template, assigns)
  end

  # show item view
  def mount(%{"job_id" => job_id, "id" => item_id}, _session, socket) do
    item = Manager.get_item!(item_id)
    next_item = Manager.next_item(item)

    {:ok, assign(socket, template: "show.html", item: item, next_item: next_item, job_id: job_id)}
  end

  # index view
  def mount(%{"job_id" => job_id} = params, _session, socket) do
    page = Map.get(params, "page", "1") |> String.to_integer()
    search = Map.get(params, "search", nil)

    %{
      entries: rows,
      page_number: page_number,
      total_pages: total_pages
    } = Manager.list_items(job_id, page: page, search: search)

    live_update(socket, :update_items)

    {:ok,
     assign(socket,
       template: "index.html",
       page: page_number,
       total_pages: total_pages,
       job_id: job_id,
       rows: rows
     )}
  end

  def handle_info(:update_items, socket) do
    job_id = socket.assigns.job_id
    search = socket.assigns.search
    page = socket.assigns.page

    %{
      entries: rows,
      total_pages: total_pages
    } = Manager.list_items(job_id, page: page, search: search)

    # If job is still running, we will update the item view
    %{state: state} = Manager.get_job!(job_id)

    if state == "running" or state == "new" do
      live_update(socket, :update_items)
    end

    {:noreply, assign(socket, total_pages: total_pages, rows: rows)}
  end

  def handle_params(params, _url, socket) do
    search =
      case Map.get(params, "search") do
        search when search == nil or search == "" ->
          nil

        search ->
          search
      end

    {:noreply, assign(socket, search: search)}
  end

  def handle_event("search", %{"search" => search}, socket) do
    job_id = socket.assigns.job_id
    page = socket.assigns.page

    %{
      entries: rows,
      total_pages: total_pages
    } = Manager.list_items(job_id, page: page, search: search)

    {:noreply, assign(socket, total_pages: total_pages, rows: rows, search: search)}
  end

  def handle_event("show_item", %{"job" => job_id, "item" => item_id}, socket) do
    {:noreply,
     push_redirect(socket,
       to: CrawlyUIWeb.Router.Helpers.item_path(socket, :show, job_id, item_id)
     )}
  end

  def handle_event("job_items", %{"job" => job_id}, socket) do
    {:noreply,
     push_redirect(socket, to: CrawlyUIWeb.Router.Helpers.item_path(socket, :index, job_id))}
  end

  def handle_event("goto_page", %{"page" => page}, socket) do
    job_id = socket.assigns.job_id

    {:noreply,
     push_redirect(socket,
       to:
         CrawlyUIWeb.Router.Helpers.item_path(socket, :index, job_id,
           page: page,
           search: socket.assigns.search
         )
     )}
  end

  defp live_update(socket, state, time \\ update_interval()) do
    if connected?(socket), do: Process.send_after(self(), state, time)
  end

  defp update_interval() do
    settings = Application.get_env(:crawly_ui, __MODULE__, [])
    Keyword.get(settings, :update_interval, 10_000)
  end
end
