defmodule Cars.MixProject do
  use Mix.Project

  def project do
    [
      app: :cars,
      version: "0.1.0",
      elixir: "~> 1.8",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  def application do
    [
      extra_applications: [:logger],
      mod: {Cars.Application, []}
    ]
  end

  defp deps do
    [
      {:crawly, "~> 0.12.0"},
      {:floki, "~> 0.26.0"},
      {:erlang_node_discovery, git: "https://github.com/oltarasenko/erlang-node-discovery"}
    ]
  end
end
