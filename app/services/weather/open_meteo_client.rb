require "json"
require "net/http"

module Weather
  class OpenMeteoClient
    Result = Struct.new(
      :temperature,
      :temperature_unit,
      :apparent_temperature,
      :wind_speed,
      :wind_speed_unit,
      :condition_label,
      :fetched_at,
      keyword_init: true
    )

    class Error < StandardError; end
    class RequestError < Error; end
    class MissingDataError < Error; end

    WEATHER_CODES = {
      0 => "Clear sky",
      1 => "Mainly clear",
      2 => "Partly cloudy",
      3 => "Overcast",
      45 => "Fog",
      48 => "Depositing rime fog",
      51 => "Light drizzle",
      53 => "Moderate drizzle",
      55 => "Dense drizzle",
      56 => "Light freezing drizzle",
      57 => "Dense freezing drizzle",
      61 => "Slight rain",
      63 => "Moderate rain",
      65 => "Heavy rain",
      66 => "Light freezing rain",
      67 => "Heavy freezing rain",
      71 => "Slight snow",
      73 => "Moderate snow",
      75 => "Heavy snow",
      77 => "Snow grains",
      80 => "Slight rain showers",
      81 => "Moderate rain showers",
      82 => "Violent rain showers",
      85 => "Slight snow showers",
      86 => "Heavy snow showers",
      95 => "Thunderstorm",
      96 => "Thunderstorm with slight hail",
      99 => "Thunderstorm with heavy hail"
    }.freeze

    def self.call(latitude:, longitude:)
      new(latitude:, longitude:).call
    end

    def initialize(latitude:, longitude:)
      @latitude = latitude
      @longitude = longitude
      @base_url = ENV.fetch("OPEN_METEO_BASE_URL", "https://api.open-meteo.com")
    end

    def call
      response = perform_request
      parse_response(response)
    end

    private

    attr_reader :latitude, :longitude, :base_url

    def perform_request
      uri = URI("#{base_url}/v1/forecast")
      uri.query = URI.encode_www_form(
        latitude:,
        longitude:,
        current: "temperature_2m,apparent_temperature,weather_code,wind_speed_10m",
        timezone: "auto"
      )

      request = Net::HTTP::Get.new(uri)
      request["Accept"] = "application/json"

      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = uri.scheme == "https"
      http.open_timeout = 5
      http.read_timeout = 5

      response = http.request(request)
      return response if response.is_a?(Net::HTTPSuccess)

      raise RequestError, "Weather request failed with #{response.code}."
    rescue SocketError, Timeout::Error, Errno::ECONNREFUSED, OpenSSL::SSL::SSLError => error
      raise RequestError, "Weather request failed: #{error.message}"
    end

    def parse_response(response)
      payload = JSON.parse(response.body)
      current = payload["current"]
      units = payload["current_units"]

      raise MissingDataError, "Weather provider did not return current conditions." if current.blank? || units.blank?

      Result.new(
        temperature: current.fetch("temperature_2m"),
        temperature_unit: units.fetch("temperature_2m"),
        apparent_temperature: current.fetch("apparent_temperature"),
        wind_speed: current.fetch("wind_speed_10m"),
        wind_speed_unit: units.fetch("wind_speed_10m"),
        condition_label: WEATHER_CODES.fetch(current.fetch("weather_code"), "Unknown"),
        fetched_at: current.fetch("time")
      )
    rescue JSON::ParserError
      raise RequestError, "Weather provider returned an invalid response."
    end
  end
end
