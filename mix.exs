defmodule ExScript.Mixfile do
  use Mix.Project

  def package do
    [
      name: :exscript,
      files: ["lib", "mix.exs", "README*", "LICENSE*"],
      maintainers: ["Craig Spaeth"],
      licenses: ["MIT"],
      links: %{"GitHub" => "https://github.com/craigspaeth/exscript"}
    ]
  end

  def project do
    [
      app: :exscript,
      version: "0.1.0",
      elixir: "~> 1.5",
      build_embedded: Mix.env() == :prod,
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      package: package()
    ]
  end

  def deps do
    [
      {:poison, "~> 2.2"},
      {:mix_test_watch, "~> 0.3", only: [:dev, :test], runtime: false},
      {:uuid, "~> 1.1"}
    ]
  end
end
