require "test_helper"

class ForecastFlowTest < ActionDispatch::IntegrationTest
  test "renders the lookup form" do
    get root_path

    assert_response :success
    assert_select "h1", "Weather lookup by address"
    assert_select "form"
  end

  test "shows an error when address is blank" do
    get forecasts_path, params: { forecast: { address: "" } }

    assert_response :unprocessable_content
    assert_select ".flash-alert", "Enter an address to look up the forecast."
  end

  test "shows cache indicator when forecast is served from cache" do
    location = Geocoding::GoogleGeocoder::Result.new(
      address: "1600 Amphitheatre Parkway",
      formatted_address: "1600 Amphitheatre Pkwy, Mountain View, CA 94043, USA",
      zip_code: "94043",
      latitude: 37.422,
      longitude: -122.084
    )

    forecast = Weather::OpenMeteoClient::Result.new(
      temperature: 20.1,
      temperature_unit: "C",
      apparent_temperature: 19.4,
      wind_speed: 7.8,
      wind_speed_unit: "km/h",
      condition_label: "Mainly clear",
      fetched_at: "2026-05-20T16:00",
      daily_high: 22.5,
      daily_low: 14.0,
      daily_periods: [
        Weather::OpenMeteoClient::DailyForecast.new(
          date: "2026-05-20",
          high: 22.5,
          low: 14.0,
          condition_label: "Mainly clear"
        )
      ]
    )

    lookup = ForecastLookup::Result.new(location:, current_forecast: forecast, cached: true)

    stub_singleton_method(ForecastLookup, :call, lookup) do
      get forecasts_path, params: { forecast: { address: "1600 Amphitheatre Parkway" } }

      assert_response :success
      assert_select ".cache-badge", "From cache"
      assert_select "h2", "Mainly clear"
    end
  end
end
