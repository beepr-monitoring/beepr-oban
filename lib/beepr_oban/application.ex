defmodule BeeprOban.Application do
  @moduledoc false
  use Application

  def start(_type, _args) do
    children = [
      {Finch,
       name: BeeprObanFinch,
       pools: %{
         :default => [size: 2]
       }},
      {
        BeeprOban.TelemetryHandler,
        []
      }
    ]

    Supervisor.start_link(children, strategy: :one_for_one)
  end
end
