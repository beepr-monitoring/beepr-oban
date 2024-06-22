# Beepr Oban

Beepr Oban is an Elixir library that connects Oban to Beepr. It calls the Beepr
monitoring endpoint when an Oban job ends by listing (using `:telemetry`) for
events.

## Installation

Add `beepr_oban` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:beepr_oban, git: "https://github.com/beepr-monitoring/beepr-oban.git", branch: "main"},
  ]
end
```

Then, run `mix deps.get` to fetch the dependencies.

## Usage

First, start the `BeeprOban` module in your application supervision tree:

```elixir
defmodule YourApp.Application do
  use Application

  def start(_type, _args) do
    children = [
      {BeeprOban, [
        monitors: %{
            YourApp.SomeWorker => "<url-your-get-from-the-beepr-admin>"
            # Add more monitors here if needed
          }
      ]}
      # Add other children here if needed
    ]

    opts = [strategy: :one_for_one, name: YourApp.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
```

This will automatically start listening for Oban job end events and trigger HTTP POST requests.

## Contributing

Contributions are welcome! For major changes, please open an issue first to discuss what you would like to change.

Please make sure to update tests as appropriate.

## License

[MIT](https://choosealicense.com/licenses/mit/)
