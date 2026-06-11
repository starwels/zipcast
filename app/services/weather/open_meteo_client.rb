require "json"
require "net/http"

module Weather
  class OpenMeteoClient
    class Error < StandardError; end
    class RequestError < Error; end
    class MissingDataError < Error; end

    BASE_URL_ENV_KEY = "OPEN_METEO_BASE_URL".freeze
    DEFAULT_BASE_URL = "https://api.open-meteo.com".freeze
    FORECAST_PATH = "/v1/forecast".freeze
    BASE_URL = ENV[BASE_URL_ENV_KEY].presence || DEFAULT_BASE_URL

    HTTPS_SCHEME = "https".freeze
    REQUEST_TIMEOUT_SECONDS = 5

    CURRENT_FIELDS = "temperature_2m,apparent_temperature,weather_code,wind_speed_10m".freeze
    DAILY_FIELDS = "weather_code,temperature_2m_max,temperature_2m_min".freeze
    FORECAST_DAYS = 5
    TIMEZONE = "auto".freeze

    APPARENT_TEMPERATURE_KEY = "apparent_temperature".freeze
    CURRENT_KEY = "current".freeze
    CURRENT_UNITS_KEY = "current_units".freeze
    DAILY_KEY = "daily".freeze
    TEMPERATURE_KEY = "temperature_2m".freeze
    TEMPERATURE_MAX_KEY = "temperature_2m_max".freeze
    TEMPERATURE_MIN_KEY = "temperature_2m_min".freeze
    TIME_KEY = "time".freeze
    WEATHER_CODE_KEY = "weather_code".freeze
    WIND_SPEED_KEY = "wind_speed_10m".freeze

    CURRENT_DATA_MISSING_MESSAGE = "Weather provider did not return current conditions.".freeze
    DAILY_DATA_MISSING_MESSAGE = "Weather provider did not return daily forecast data.".freeze
    INVALID_RESPONSE_MESSAGE = "Weather provider returned an invalid response.".freeze
    UNKNOWN_CONDITION = "Unknown".freeze

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
    end

    def call
      response = perform_request
      parse_response(response)
    end

    private

    attr_reader :latitude, :longitude

    def perform_request
      uri = URI("#{BASE_URL}#{FORECAST_PATH}")
      uri.query = URI.encode_www_form(
        latitude:,
        longitude:,
        current: CURRENT_FIELDS,
        daily: DAILY_FIELDS,
        forecast_days: FORECAST_DAYS,
        timezone: TIMEZONE
      )

      request = Net::HTTP::Get.new(uri)
      request["Accept"] = "application/json"

      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = uri.scheme == HTTPS_SCHEME
      http.open_timeout = REQUEST_TIMEOUT_SECONDS
      http.read_timeout = REQUEST_TIMEOUT_SECONDS

      response = http.request(request)
      return response if response.is_a?(Net::HTTPSuccess)

      raise RequestError, "Weather request failed with #{response.code}."
    rescue SocketError, Timeout::Error, Errno::ECONNREFUSED, OpenSSL::SSL::SSLError => error
      raise RequestError, "Weather request failed: #{error.message}"
    end

    def parse_response(response)
      payload = JSON.parse(response.body)
      current = payload[CURRENT_KEY]
      units = payload[CURRENT_UNITS_KEY]
      daily = payload[DAILY_KEY]

      raise MissingDataError, CURRENT_DATA_MISSING_MESSAGE if current.blank? || units.blank?
      raise MissingDataError, DAILY_DATA_MISSING_MESSAGE if daily.blank?

      daily_periods = build_daily_periods(daily)

      Forecast.new(
        temperature: current.fetch(TEMPERATURE_KEY),
        temperature_unit: units.fetch(TEMPERATURE_KEY),
        apparent_temperature: current.fetch(APPARENT_TEMPERATURE_KEY),
        wind_speed: current.fetch(WIND_SPEED_KEY),
        wind_speed_unit: units.fetch(WIND_SPEED_KEY),
        condition_label: WEATHER_CODES.fetch(current.fetch(WEATHER_CODE_KEY), UNKNOWN_CONDITION),
        fetched_at: current.fetch(TIME_KEY),
        daily_high: daily_periods.first&.high,
        daily_low: daily_periods.first&.low,
        daily_periods:
      )
    rescue JSON::ParserError
      raise RequestError, INVALID_RESPONSE_MESSAGE
    end

    def build_daily_periods(daily)
      dates = daily.fetch(TIME_KEY)
      highs = daily.fetch(TEMPERATURE_MAX_KEY)
      lows = daily.fetch(TEMPERATURE_MIN_KEY)
      codes = daily.fetch(WEATHER_CODE_KEY)

      dates.each_index.map do |index|
        DailyForecast.new(
          date: dates[index],
          high: highs[index],
          low: lows[index],
          condition_label: WEATHER_CODES.fetch(codes[index], UNKNOWN_CONDITION)
        )
      end
    end
  end
end
