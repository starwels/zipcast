require "application_system_test_case"

class ForecastLookupTest < ApplicationSystemTestCase
  test "shows validation feedback for blank address" do
    visit root_path

    click_on "Look up forecast"

    assert_text "Enter an address to look up the forecast."
  end

  test "shows forecast result for submitted address" do
    stub_singleton_method(ForecastLookup, :call, successful_lookup) do
      visit root_path

      fill_in "Address", with: "1600 Amphitheatre Parkway"
      click_on "Look up forecast"

      assert_text "1600 Amphitheatre Pkwy, Mountain View, CA 94043, USA"
      assert_text "Mainly clear"
      assert_text "FROM CACHE"
      assert_text "Next five days"
    end
  end

  private

  def successful_lookup
    location = Geocoding::Location.new(
      address: "1600 Amphitheatre Parkway",
      formatted_address: "1600 Amphitheatre Pkwy, Mountain View, CA 94043, USA",
      zip_code: "94043",
      latitude: 37.422,
      longitude: -122.084
    )

    forecast = Weather::Forecast.new(
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
        Weather::DailyForecast.new(
          date: "2026-05-20",
          high: 22.5,
          low: 14.0,
          condition_label: "Mainly clear"
        )
      ]
    )

    ForecastLookup::Result.new(location:, current_forecast: forecast, cached: true)
  end
end
