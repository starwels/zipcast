class ForecastsController < ApplicationController
  def new
    @address = ""
  end

  def create
    @address = forecast_params[:address].to_s.strip

    if @address.blank?
      flash.now[:alert] = "Enter an address to look up the forecast."
      render :new, status: :unprocessable_entity
    else
      flash.now[:notice] = "Address received. Weather lookup will be added next."
      render :new, status: :ok
    end
  end

  private

  def forecast_params
    params.expect(forecast: [ :address ])
  end
end
