use Mix.Config

config :erlang_node_discovery,
  hosts: ["127.0.0.1", "crawlyui.com"],
  node_ports: [
    {:ui, 0}
  ]

ui_node = System.get_env("UI_NODE") || "ui@127.0.0.1"
ui_node = ui_node |> String.to_atom()

user_agents = [
  "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/61.0.3163.100 Safari/537.36",
  "Mozilla/5.0 (Linux; Android 6.0.1; RedMi Note 5 Build/RB3N5C; wv) AppleWebKit/537.36 (KHTML, like Gecko) Version/4.0 Chrome/68.0.3440.91 Mobile Safari/537.36",
  "Mozilla/4.0 (compatible; MSIE 7.0; Windows NT 6.1; WOW64; Trident/6.0; SLCC2; .NET CLR 2.0.50727; .NET CLR 3.5.30729; .NET CLR 3.0.30729; Media Center PC 6.0; .NET4.0C; .NET4.0E; Microsoft Outlook 14.0.7113; ms-office; MSOffice 14)",
  "Mozilla/5.0 (BB10; Kbd) AppleWebKit/537.35+ (KHTML, like Gecko) Version/10.3.1.2243 Mobile Safari/537.35+",
  "Mozilla/5.0 (Linux; Android 4.4.2; QMV7A Build/KOT49H) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/36.0.1985.135 Safari/537.36",
  "Mozilla/5.0 (Linux; Android 4.4.2; en-us; SAMSUNG SM-P600 Build/KOT49H) AppleWebKit/537.36 (KHTML, like Gecko) Version/1.5 Chrome/28.0.1500.94 Safari/537.36",
  "Mozilla/5.0 (Windows NT 6.0) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/41.0.2231.0 Safari/537.36",
  "Mozilla/5.0 (iPhone; CPU iPhone OS 7_1_2 like Mac OS X) AppleWebKit/537.51.2 (KHTML, like Gecko) CriOS/43.0.2357.51 Mobile/11D257 Safari/9537.53",
  "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/37.0.2062.94 Safari/537.36",
  "Mozilla/5.0 (Linux; U; Android 4.0.3; en-us; HTC_C715c Build/IML74K) AppleWebKit/534.30 (KHTML, like Gecko) Version/4.0 Mobile Safari/534.30",
  "Mozilla/4.0 (compatible; MSIE 6.0; Windows NT 5.1; WOW64; Trident/4.0; .NET4.0E; .NET4.0C; .NET CLR 3.5.30729; .NET CLR 2.0.50727; .NET CLR 3.0.30729; 360SE)"
]

config :crawly,
  closespider_timeout: 1,
  closespider_itemcount: 100_000,
  concurrent_requests_per_domain: 2,
  middlewares: [
    Crawly.Middlewares.DomainFilter,
    Crawly.Middlewares.UniqueRequest,
    {Crawly.Middlewares.UserAgent, user_agents: user_agents}
  ],
  pipelines: [
    {Crawly.Pipelines.Validate, fields: [:url, :title, :id, :price, :image]},
    {Crawly.Pipelines.DuplicatesFilter, item_id: :id},
    {Crawly.Pipelines.Experimental.SendToUI, ui_node: ui_node},
    Crawly.Pipelines.JSONEncoder,
    {Crawly.Pipelines.WriteToFile, extension: "json", folder: "/tmp"}
  ]

# tell logger to load a LoggerFileBackend processes
config :logger,
  backends: [
    :console,
    {Crawly.Loggers.SendToUiBackend, :send_log_to_ui}
  ],
  level: :debug

config :logger, :send_log_to_ui, destination: {ui_node, CrawlyUI, :store_log}
