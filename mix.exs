defmodule BeeprOban.MixProject do
  use Mix.Project

  def project do
    [
      app: :beepr_oban,
      version: "0.1.0",
      elixir: "~> 1.16",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      test_coverage: [summary: [threshold: 100]]
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      mod: {BeeprOban.Application, []},
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:telemetry, "~> 1.0"},
      {:req, ">= 0.4.0"},
      {:bypass, ">= 2.1.0", only: :test},
      {:mix_test_watch, ">= 1.0.0", only: [:dev, :test], runtime: false},
      {:styler, "~> 1.0.0-rc.1", only: [:dev, :test], runtime: false}
    ]
  end
end
