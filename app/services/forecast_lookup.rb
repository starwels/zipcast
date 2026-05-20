class ForecastLookup
  Result = Struct.new(:location, :current_forecast, :cached, keyword_init: true)

  class Error < StandardError; end

  def self.call(address:)
    new(address:).call
  end

  def initialize(address:)
    @address = address
  end

  def call
    location = Geocoding::GoogleGeocoder.call(address:)
    forecast, cached = fetch_forecast_for(location)

    Result.new(location:, current_forecast: forecast, cached:)
  rescue Geocoding::GoogleGeocoder::Error, Weather::OpenMeteoClient::Error => error
    raise Error, error.message
  end

  private

  attr_reader :address

  def fetch_forecast_for(location)
    cache_key = "forecast:zip:#{location.zip_code}"
    cached_forecast = Rails.cache.read(cache_key)
    return [ cached_forecast, true ] if cached_forecast.present?

    forecast = Weather::OpenMeteoClient.call(
      latitude: location.latitude,
      longitude: location.longitude
    )

    Rails.cache.write(cache_key, forecast, expires_in: 30.minutes)
    [ forecast, false ]
  end
end
