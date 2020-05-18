use Mix.Config
config :erlang_node_discovery,
       hosts: ["127.0.0.1", "crawlyui.com"],
       node_ports: [
         {:ui, 0}
       ]

ui_node = System.get_env("UI_NODE") || "ui@127.0.0.1"
ui_node = ui_node |> String.to_atom()

config :crawly,
       closespider_timeout: -1,
       closespider_itemcount: 100_000,
       concurrent_requests_per_domain: 2,
       middlewares: [
         Crawly.Middlewares.DomainFilter,
         Crawly.Middlewares.UniqueRequest,
         {Crawly.Middlewares.UserAgent, user_agents: ["Crawly Bot"]}
       ],
       pipelines: [
         {Crawly.Pipelines.Validate, fields: [:url, :title, :id, :price, :image]},
         {Crawly.Pipelines.DuplicatesFilter, item_id: :id},
         {Crawly.Pipelines.Experimental.SendToUI, ui_node: ui_node},
         Crawly.Pipelines.JSONEncoder,
         {Crawly.Pipelines.WriteToFile, extension: "json", folder: "/tmp"}
       ]