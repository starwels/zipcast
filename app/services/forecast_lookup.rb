class ForecastLookup
  Result = Struct.new(:location, :current_forecast, :cached, keyword_init: true)

  class Error < StandardError; end

  CACHE_KEY_PREFIX = "forecast:zip".freeze
  CACHE_EXPIRATION = 30.minutes

  def self.call(address:, geocoder: Geocoding::GoogleGeocoder, weather_client: Weather::OpenMeteoClient, cache: Rails.cache)
    new(address:, geocoder:, weather_client:, cache:).call
  end

  def initialize(address:, geocoder: Geocoding::GoogleGeocoder, weather_client: Weather::OpenMeteoClient, cache: Rails.cache)
    @address = address
    @geocoder = geocoder
    @weather_client = weather_client
    @cache = cache
  end

  def call
    location = geocoder.call(address:)
    forecast, cached = fetch_forecast_for(location)

    Result.new(location:, current_forecast: forecast, cached:)
  rescue Geocoding::GoogleGeocoder::Error, Weather::OpenMeteoClient::Error => error
    raise Error, error.message
  end

  private

  attr_reader :address, :geocoder, :weather_client, :cache

  def fetch_forecast_for(location)
    cache_key = "#{CACHE_KEY_PREFIX}:#{location.zip_code}"
    cached_forecast = cache.read(cache_key)
    return [ cached_forecast, true ] if cached_forecast.present?

    forecast = weather_client.call(
      latitude: location.latitude,
      longitude: location.longitude
    )

    cache.write(cache_key, forecast, expires_in: CACHE_EXPIRATION)
    [ forecast, false ]
  end
end
