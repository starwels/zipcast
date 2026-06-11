require "test_helper"

class ForecastLookupTest < ActiveSupport::TestCase
  FakeGeocoder = Struct.new(:response) do
    def call(**_args)
      response
    end
  end

  FakeWeatherClient = Struct.new(:response, :calls) do
    def call(**_args)
      self.calls += 1
      response
    end
  end

  setup do
    @memory_cache = ActiveSupport::Cache.lookup_store(:memory_store)
    @memory_cache.clear
  end

  test "caches forecast responses by zip code" do
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
      daily_periods: []
    )

    geocoder = FakeGeocoder.new(location)
    weather_client = FakeWeatherClient.new(forecast, 0)

    first_lookup = ForecastLookup.call(
      address: "1600 Amphitheatre Parkway",
      geocoder:,
      weather_client:,
      cache: @memory_cache
    )
    second_lookup = ForecastLookup.call(
      address: "1600 Amphitheatre Parkway",
      geocoder:,
      weather_client:,
      cache: @memory_cache
    )

    assert_equal false, first_lookup.cached
    assert_equal true, second_lookup.cached
    assert_equal 1, weather_client.calls
  end

  test "wraps geocoding errors" do
    geocoder = ->(**_args) {
      raise Geocoding::GoogleGeocoder::NoResultsError, "No location found for that address."
    }

    error = assert_raises(ForecastLookup::Error) do
      ForecastLookup.call(address: "Unknown", geocoder:, cache: @memory_cache)
    end

    assert_equal "No location found for that address.", error.message
  end

  test "wraps weather provider errors" do
    location = Geocoding::Location.new(
      address: "1600 Amphitheatre Parkway",
      formatted_address: "1600 Amphitheatre Pkwy, Mountain View, CA 94043, USA",
      zip_code: "94043",
      latitude: 37.422,
      longitude: -122.084
    )

    geocoder = FakeGeocoder.new(location)
    weather_client = ->(**_args) {
      raise Weather::OpenMeteoClient::RequestError, "Weather request failed with 500."
    }

    error = assert_raises(ForecastLookup::Error) do
      ForecastLookup.call(address: "1600 Amphitheatre Parkway", geocoder:, weather_client:, cache: @memory_cache)
    end

    assert_equal "Weather request failed with 500.", error.message
  end
end
