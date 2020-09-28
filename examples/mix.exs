defmodule Shops.MixProject do
  use Mix.Project

  def project do
    [
      app: :shops,
      version: "0.1.0",
      elixir: "~> 1.8",
      erlc_paths: ["lib", "lib/shops"],
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger],
      mod: {Shops.Application, []}
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:crawly, "~> 0.11.0"},
      {:floki, "~> 0.26.0"},
      {:erlang_node_discovery, git: "https://github.com/oltarasenko/erlang-node-discovery"}
    ]
  end
end
