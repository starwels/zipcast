class ForecastsController < ApplicationController
  def new
    @address = ""
    @location = nil
    @current_forecast = nil
  end

  def create
    @address = forecast_params[:address].to_s.strip
    @location = nil
    @current_forecast = nil

    if @address.blank?
      flash.now[:alert] = "Enter an address to look up the forecast."
      render :new, status: :unprocessable_entity
    else
      @location = Geocoding::GoogleGeocoder.call(address: @address)
      @current_forecast = Weather::OpenMeteoClient.call(
        latitude: @location.latitude,
        longitude: @location.longitude
      )
      flash.now[:notice] = "Address resolved successfully."
      render :new, status: :ok
    end
  rescue Geocoding::GoogleGeocoder::Error => error
    flash.now[:alert] = error.message
    render :new, status: :unprocessable_entity
  rescue Weather::OpenMeteoClient::Error => error
    flash.now[:alert] = error.message
    render :new, status: :unprocessable_entity
  end

  private

  def forecast_params
    params.expect(forecast: [ :address ])
  end
end
