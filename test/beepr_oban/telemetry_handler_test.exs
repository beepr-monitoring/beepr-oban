defmodule BeeprOban.TelemetryHandlerTest do
  use ExUnit.Case, async: true

  import ExUnit.CaptureLog

  alias BeeprOban.TelemetryHandler
  alias Oban.Plugins.Cron

  setup do
    bypass = Bypass.open()

    ref =
      :telemetry_test.attach_event_handlers(
        self(),
        [[:beepr_oban, :request, :stop]]
      )

    {:ok, bypass: bypass, completed_ref: ref}
  end

  test "prepare_monitors/1 converts keys to strings" do
    assert %{MyModule: 1} |> TelemetryHandler.prepare_monitors() |> Map.keys() == [":MyModule"]
  end

  test "initializes with to a state with known keys" do
    assert %{job_urls: %{}, base_request: _} = :sys.get_state(TelemetryHandler)
  end

  test "handles :oban plugin stop event and notifies endpoint", %{bypass: bypass, completed_ref: completed_ref} do
    monitor_check_url = endpoint_url(bypass)

    Bypass.expect_once(bypass, "POST", "/", fn conn ->
      Plug.Conn.resp(conn, 200, "")
    end)

    setup_test_state(%{"TestWorker" => monitor_check_url})

    job = %{worker: "TestWorker"}
    :telemetry.execute([:oban, :plugin, :stop], %{}, %{plugin: Cron, jobs: [job]})
    assert_request_completed(completed_ref)
  end

  test "logs error when notification request fails", %{bypass: bypass, completed_ref: completed_ref} do
    monitor_check_url = endpoint_url(bypass)

    Bypass.expect_once(bypass, "POST", "/", fn conn ->
      Plug.Conn.resp(conn, 500, "ERROR")
    end)

    setup_test_state(%{"TestWorker" => monitor_check_url})

    job = %{worker: "TestWorker"}

    {_, log} =
      with_log(fn ->
        :telemetry.execute([:oban, :plugin, :stop], %{}, %{plugin: Cron, jobs: [job]})
        assert_request_completed(completed_ref)
      end)

    assert log =~ "Error when notifying Beepr"
  end

  test "logs unexpected error when request fails", %{completed_ref: completed_ref} do
    setup_test_state(%{"TestWorker" => "http://"})

    job = %{worker: "TestWorker"}

    {_, log} =
      with_log(fn ->
        :telemetry.execute([:oban, :plugin, :stop], %{}, %{plugin: Cron, jobs: [job]})
        assert_request_completed(completed_ref)
      end)

    assert log =~ "Unexpected error when notifying Beepr"
  end

  defp assert_request_completed(ref) do
    assert_receive {[:beepr_oban, :request, :stop], ^ref, %{}, %{}}
  end

  defp setup_test_state(job_urls) do
    :ok =
      GenServer.call(
        TelemetryHandler,
        {:update_state,
         fn state ->
           state
           |> Map.update(:base_request, Req.new(), fn req ->
             Req.merge(req, max_retries: 0)
           end)
           |> Map.put(:job_urls, job_urls)
         end}
      )
  end

  defp endpoint_url(%{port: port}), do: "http://localhost:#{port}/"
end
