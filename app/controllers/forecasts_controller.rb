class ForecastsController < ApplicationController
  def index
    @address = ""
    @location = nil
    @current_forecast = nil
    @cache_hit = false

    unless params.key?(:forecast)
      render :new
      return
    end

    @address = params.dig(:forecast, :address).to_s.strip

    if @address.blank?
      flash.now[:alert] = "Enter an address to look up the forecast."
      render :new, status: :unprocessable_content
      return
    end

    lookup = ForecastLookup.call(address: @address)
    @location = lookup.location
    @current_forecast = lookup.current_forecast
    @cache_hit = lookup.cached
    flash.now[:notice] = @cache_hit ? "Forecast loaded from cache." : "Forecast loaded successfully."
    render :new
  rescue ForecastLookup::Error, Geocoding::GoogleGeocoder::Error => error
    flash.now[:alert] = error.message
    render :new, status: :unprocessable_content
  end
end
