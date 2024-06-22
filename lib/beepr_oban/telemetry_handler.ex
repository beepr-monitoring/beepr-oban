defmodule BeeprOban.TelemetryHandler do
  @moduledoc false
  use GenServer

  require Logger

  def start_link(_config) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init(_config) do
    :ok =
      :telemetry.attach(
        to_string(__MODULE__),
        [:oban, :plugin, :stop],
        &__MODULE__.handle_event/4,
        nil
      )

    job_urls =
      :beepr_oban
      |> Application.get_env(:monitors, %{})
      |> prepare_monitors()

    {:ok, %{job_urls: job_urls, base_request: base_request()}}
  end

  def prepare_monitors(monitors) do
    Map.new(monitors, fn {k, v} -> {inspect(k), v} end)
  end

  def handle_event([:oban, :plugin, :stop], _measurements, metadata, _metrics) do
    if Access.get(metadata, :plugin) == Oban.Plugins.Cron do
      for job <- Access.get(metadata, :jobs, []) do
        GenServer.cast(__MODULE__, {:notify_endpoint, job.worker})
      end
    end
  end

  def handle_call({:update_state, func}, _, state) do
    {:reply, :ok, func.(state)}
  end

  def handle_cast({:notify_endpoint, job}, %{job_urls: job_urls, base_request: base_request} = state) do
    if url = Map.get(job_urls, job) do
      :telemetry.span([:beepr_oban, :request], %{}, fn ->
        {execute_request(base_request, url), %{}}
      end)
    end

    {:noreply, state}
  end

  defp execute_request(base_request, url) do
    request = Req.merge(base_request, url: url)

    case Req.request(request) do
      {:ok, %{status: 200}} ->
        nil

      {:ok, %{status: status}} ->
        Logger.warning("Error when notifying Beepr", url: url, status: status)

      {:error, err} ->
        Logger.error("Unexpected error when notifying Beepr", url: url, error: err)
    end
  end

  defp base_request do
    Req.new(
      method: :post,
      finch: BeeprObanFinch,
      retry: :transient,
      max_retries: 2
    )
  end
end
