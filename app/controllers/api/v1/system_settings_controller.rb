class Api::V1::SystemSettingsController < ApplicationController
  respond_to :json

  def show
    respond_with SystemSetting.find(params[:id])
  end

  def update
    system_settings = SystemSetting.find(params[:id])

    if system_settings.update(system_settings_params)
      render json: system_settings, status: 200, location: [:api, system_settings]
      return
    end

    render json: { errors: system_settings.errors }, status: 422
  end

  private

    def system_settings_params
      params.require( :system_settings ).permit( :cost_per_location, :units_per_location, :cost_high_value )
    end

end

