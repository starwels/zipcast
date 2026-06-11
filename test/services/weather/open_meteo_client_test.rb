require "test_helper"

class Weather::OpenMeteoClientTest < ActiveSupport::TestCase
  FakeHttp = Struct.new(:response) do
    attr_accessor :use_ssl, :open_timeout, :read_timeout

    def request(_request)
      response
    end
  end

  test "returns current conditions and extended forecast" do
    payload = {
      current: {
        temperature_2m: 20.1,
        apparent_temperature: 19.4,
        weather_code: 1,
        wind_speed_10m: 7.8,
        time: "2026-05-20T16:00"
      },
      current_units: {
        temperature_2m: "C",
        wind_speed_10m: "km/h"
      },
      daily: {
        time: %w[2026-05-20 2026-05-21],
        temperature_2m_max: [ 22.5, 24.0 ],
        temperature_2m_min: [ 14.0, 15.2 ],
        weather_code: [ 1, 61 ]
      }
    }

    fake_http = FakeHttp.new(http_response(code: "200", body: JSON.generate(payload)))

    stub_singleton_method(Net::HTTP, :new, fake_http) do
      result = Weather::OpenMeteoClient.call(latitude: 37.422, longitude: -122.084)

      assert_equal 20.1, result.temperature
      assert_equal "C", result.temperature_unit
      assert_equal "Mainly clear", result.condition_label
      assert_equal 22.5, result.daily_high
      assert_equal 14.0, result.daily_low
      assert_equal 2, result.daily_periods.size
      assert_equal "Slight rain", result.daily_periods.last.condition_label
    end
  end

  test "raises when current conditions are missing" do
    fake_http = FakeHttp.new(http_response(code: "200", body: JSON.generate({ current_units: {}, daily: {} })))

    stub_singleton_method(Net::HTTP, :new, fake_http) do
      error = assert_raises(Weather::OpenMeteoClient::MissingDataError) do
        Weather::OpenMeteoClient.call(latitude: 37.422, longitude: -122.084)
      end

      assert_equal "Weather provider did not return current conditions.", error.message
    end
  end

  test "raises when daily forecast data is missing" do
    payload = {
      current: {
        temperature_2m: 20.1,
        apparent_temperature: 19.4,
        weather_code: 1,
        wind_speed_10m: 7.8,
        time: "2026-05-20T16:00"
      },
      current_units: {
        temperature_2m: "C",
        wind_speed_10m: "km/h"
      }
    }

    fake_http = FakeHttp.new(http_response(code: "200", body: JSON.generate(payload)))

    stub_singleton_method(Net::HTTP, :new, fake_http) do
      error = assert_raises(Weather::OpenMeteoClient::MissingDataError) do
        Weather::OpenMeteoClient.call(latitude: 37.422, longitude: -122.084)
      end

      assert_equal "Weather provider did not return daily forecast data.", error.message
    end
  end

  test "raises when provider returns invalid json" do
    fake_http = FakeHttp.new(http_response(code: "200", body: "{"))

    stub_singleton_method(Net::HTTP, :new, fake_http) do
      error = assert_raises(Weather::OpenMeteoClient::RequestError) do
        Weather::OpenMeteoClient.call(latitude: 37.422, longitude: -122.084)
      end

      assert_equal "Weather provider returned an invalid response.", error.message
    end
  end

  test "raises when provider request fails" do
    fake_http = FakeHttp.new(http_response(code: "500", body: "{}"))

    stub_singleton_method(Net::HTTP, :new, fake_http) do
      error = assert_raises(Weather::OpenMeteoClient::RequestError) do
        Weather::OpenMeteoClient.call(latitude: 37.422, longitude: -122.084)
      end

      assert_equal "Weather request failed with 500.", error.message
    end
  end
end
