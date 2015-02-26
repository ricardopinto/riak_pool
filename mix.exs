defmodule RiakPool.Mixfile do
  use Mix.Project

  def project do
    [ app: :riak_pool,
      version: "0.2.2",
      elixir: ">= 0.12.0",
      name: "riak_pool",
      source_url: "https://github.com/HashNuke/riak_pool",
      homepage_url: "https://github.com/HashNuke/riak_pool",
      deps: deps ]
  end


  def application do
    [mod: []]
  end


  defp deps do
    [
      {:poolboy, "~> 1.4.2"},
      {:riak_pb, github: "basho/riak_pb", override: true, tag: "2.0.0.16", compile: "./rebar get-deps compile deps_dir=../"},
      {:riakc, github: "basho/riak-erlang-client", tag: "2.0.1"},
      {:ex_doc, github: "elixir-lang/ex_doc"}
    ]
  end
end
