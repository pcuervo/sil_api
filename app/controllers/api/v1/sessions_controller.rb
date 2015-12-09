class Api::V1::SessionsController < ApplicationController
  before_action :cors_preflight_check
  after_action :cors_set_access_control_headers

  def create
    user_password = params[:session][:password]
    user_email = params[:session][:email]
    user = user_email.present? && User.find_by(email: user_email)

    if user.blank? 
      render json: { errors: "Invalid email or password" }, status: 422
      return
    end

    if user.valid_password? user_password 
      sign_in user, store: false
      user.generate_authentication_token!
      user.save
      render json: user, status: 200, location: [:api, user]
      return
    end

    render json: { errors: "Invalid email or password" }, status: 422
  end

  def destroy
  	user = User.find_by(auth_token: params[:id])
  	user.generate_authentication_token!
  	user.save
  	head 204
  end
end