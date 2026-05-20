class ForecastsController < ApplicationController
  def new
    @address = ""
    @location = nil
    @current_forecast = nil
    @cache_hit = false
  end

  def create
    @address = forecast_params[:address].to_s.strip
    @location = nil
    @current_forecast = nil
    @cache_hit = false

    if @address.blank?
      flash.now[:alert] = "Enter an address to look up the forecast."
      render :new, status: :unprocessable_entity
    else
      lookup = ForecastLookup.call(address: @address)
      @location = lookup.location
      @current_forecast = lookup.current_forecast
      @cache_hit = lookup.cached
      flash.now[:notice] = "Forecast loaded successfully."
      render :new, status: :ok
    end
  rescue ForecastLookup::Error, Geocoding::GoogleGeocoder::Error => error
    flash.now[:alert] = error.message
    render :new, status: :unprocessable_entity
  end

  private

  def forecast_params
    params.expect(forecast: [ :address ])
  end
end
