class ForecastsController < ApplicationController
  def index
    unless params.key?(:forecast)
      render :new
      return
    end

    @address = params.dig(:forecast, :address).to_s.strip

    if @address.blank?
      flash.now[:alert] = t(".blank_address")
      render :new, status: :unprocessable_content
      return
    end

    lookup = ForecastLookup.call(address: @address)
    @location = lookup.location
    @current_forecast = lookup.current_forecast
    @cache_hit = lookup.cached
    flash.now[:notice] = @cache_hit ? t(".cache_hit") : t(".lookup_success")
    render :new
  rescue ForecastLookup::Error, Geocoding::GoogleGeocoder::Error => error
    flash.now[:alert] = error.message
    render :new, status: :unprocessable_content
  end
end
