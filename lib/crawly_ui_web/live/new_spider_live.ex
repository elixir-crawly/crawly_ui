defmodule CrawlyUIWeb.NewSpiderLive do
  use Phoenix.LiveView

  def render(assigns) do
    CrawlyUIWeb.JobView.render("new_spider.html", assigns)
  end

  @doc """
  Mounting point of the live view. Is responsible for passing all initial
  arguments.
  """
  def mount(%{"spider" => spider}, _session, socket) do
    # Try to find a spider by name, or redirect
    case CrawlyUI.Manager.get_spider!(spider) do
      nil ->
        {:ok, redirect(socket, to: "/spider/new")}

      data ->
        socket =
          socket
          |> initial_assigns()
          |> assign(%{
            updating: true,
            rules: data.rules,
            data: %{
              "name" => data.name,
              "fields" => data.fields,
              "start_urls" => data.start_urls,
              "links_to_follow" => data.links_to_follow
            }
          })

        {:ok, socket}
    end
  end

  # Create a new spider
  def mount(_params, _session, socket) do
    socket = initial_assigns(socket)
    {:ok, socket}
  end

  def handle_event("step0", _data, socket) do
    socket =
      socket
      |> assign(%{
        current_step: 0,
        title: "Step1: Define spider name and fields to extract"
      })

    {:noreply, socket}
  end

  def handle_event("step1", data, socket) do
    socket =
      socket
      |> assign(%{
        data: Map.merge(socket.assigns.data, data),
        current_step: 1,
        title: "Define crawling rules"
      })

    {:noreply, socket}
  end

  def handle_event("step2", data, socket) do
    socket =
      socket
      |> assign(%{
        data: Map.merge(socket.assigns.data, data),
        current_step: 2,
        title: "Item extractors list"
      })

    {:noreply, socket}
  end

  def handle_event("step3", data, socket) do
    url = Map.get(data, "pageUrl")

    socket =
      with {:ok, page} <- HTTPoison.get(url),
           {:ok, document} <- Floki.parse_document(page.body) do
        current_rule = %{
          "_url" => url,
          "_document" => document,
          "_page" => page.body
        }

        socket_data = %{
          error: nil,
          current_step: 3,
          current_rule: current_rule,
          title: "Define extractors"
        }

        socket |> assign(socket_data)
      else
        {:error, %HTTPoison.Error{reason: reason}} ->
          socket |> assign(%{error: reason.reason})

        {:error, reason} ->
          socket |> assign(%{error: inspect(reason)})
      end

    {:noreply, socket}
  end

  def handle_event("form_change", data, socket) do
    hints = socket.assigns.hints

    document = Map.get(socket.assigns.current_rule, "_document")
    [target] = Map.get(data, "_target")
    suggested_selector = Map.get(data, target)

    html_tree =
      case suggested_selector do
        "response_url" ->
          Map.get(socket.assigns.current_rule, "_url")

        _selector ->
          Floki.find(document, suggested_selector)
      end

    new_hints = Map.put(hints, target, "#{Floki.text(html_tree)}")

    {:noreply, socket |> assign(%{hints: new_hints, form_data: data})}
  end

  def handle_event("rule_added", rule, socket) do
    current_rules_map = socket.assigns.rules
    current_rule = Map.merge(socket.assigns.current_rule, rule)
    current_rule_url = Map.get(current_rule, "_url")
    new_rules_map = Map.put(current_rules_map, current_rule_url, current_rule)

    socket =
      socket
      |> assign(%{rules: new_rules_map, current_step: 2})

    {:noreply, post_rule_added_cleanup(socket)}
  end

  def handle_event("rule_delete", %{"url" => url}, socket) do
    rules = Map.delete(socket.assigns.rules, url)
    socket = socket |> assign(%{rules: rules, current_step: 2})
    {:noreply, socket}
  end

  def handle_event("rule_edit", %{"url" => url}, socket) do
    current_rule = Map.get(socket.assigns.rules, url)
    socket = socket |> assign(%{current_step: 3, current_rule: current_rule})
    {:noreply, socket}
  end

  def handle_event("save_spider", _data, socket) do
    attrs = Map.put(socket.assigns.data, "rules", socket.assigns.rules)

    # TODO: A very ugly create or update. We should really split this.
    case socket.assigns.updating do
      false ->
        case CrawlyUI.Manager.create_spider(attrs) do
          {:ok, _spider} ->
            {:noreply, redirect(socket, to: "/spider")}

          {:error, reason} ->
            {:noreply, assign(socket, %{error: "#{inspect(reason.errors)}"})}
        end

      true ->
        case CrawlyUI.Manager.update_spider(Map.get(socket.assigns.data, "name"), attrs) do
          {:error, reason} ->
            {:noreply, assign(socket, %{error: inspect(reason)})}

          {:ok, _} ->
            {:noreply, redirect(socket, to: "/spider")}
        end
    end
  end

  defp post_rule_added_cleanup(socket) do
    assign(socket, %{
      current_step: 2,
      error: nil,
      current_rule: %{},
      hints: %{}
    })
  end

  # Just a shortcut to assign required fields to the socket
  defp initial_assigns(socket) do
    assign(socket, %{
      # Do we make a new spider or editing already made one
      updating: false,
      current_rule: %{},
      rules: %{},
      error: nil,

      # Show how given rules will extract data from given page
      hints: %{},
      data: %{},

      # TODO: Not clear what is exactly stored here
      form_data: %{},
      current_step: 0,
      title: "Step1: Define spider name and fields to extract"
    })
  end
end
