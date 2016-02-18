class Api::V1::UsersController < ApplicationController
	before_action :authenticate_with_token!, only: [:update, :create, :destroy]
	before_action :cors_preflight_check
  after_action :cors_set_access_control_headers

	respond_to :json

	def index
		respond_with User.all
	end

	def show
		respond_with User.find(params[:id])
	end

	def create
		user = User.new(user_params)
		if user.save
			render json: user, status: 201, location: [:api, user]
			log_action( current_user.id, 'User', 'Created user "' + user.first_name + ' ' + user.last_name + '" with role ' + user.get_role , user.id )
			return
		end

		render json: { errors: user.errors }, status: 422
	end

	def update
		user = User.find(params[:id])

		if user.update(user_params)
			render json: user, status: 200, location: [:api, user]
		else
			render json: { errors: user.errors }, status: 422
		end
	end

	def change_password
		user = current_user

		if user.update(user_password_params)
			sign_in user, :bypass => true
			render json: { success: 'Se ha cambiado el password' }, status: 200
			return
		end

		render json: { errors: user.errors }, status: 422
	end

	def destroy
	  current_user.destroy
	  head 204
	end

	def get_project_managers
    respond_with User.pm_users
  end

  def get_account_executives
    respond_with User.ae_users
  end

  def get_client_contacts
    respond_with User.client_users
  end

	private	

		def user_params
			params.require(:user).permit(:first_name, :last_name, :email, :password, :password_confirmation, :role)
		end

		def user_password_params
			params.require(:user).permit(:password, :password_confirmation)
		end
end
