class Api::V1::UsersController < ApplicationController
  before_action only: [:update, :create, :destroy, :change_password, :delete] do 
    authenticate_with_token! request.headers['Authorization']
  end
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
			return
		end

		render json: { errors: user.errors }, status: 422
	end

	def update
		user = User.find(params[:id])

    if params[:avatar]
      image = Paperclip.io_adapters.for(params[:avatar])
      image.original_filename = params[:filename]
      user.avatar = image
    end

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

  def delete
    user = User.find(params[:id])
    if params[:pm].present?
      user.transfer_inventory_to( params[:pm] )
      user.transfer_deliveries_to( params[:pm] )
      user.transfer_requests_to( params[:pm] )
      user.destroy
      render json: { success: 'Se ha eliminado el usuario y se ha transferido su inventario con éxito' }
      return
    end

    if params[:ae].present?
      user.transfer_inventory_to( params[:ae] )
      user.transfer_deliveries_to( params[:ae] )
      user.transfer_requests_to( params[:ae] )
      user.destroy
      render json: { success: 'Se ha eliminado el usuario y se ha transferido su inventario con éxito' }
      return
    end

    if params[:wh_admin].present?
      user.transfer_inventory_to( params[:wh_admin] )
      user.transfer_deliveries_to( params[:wh_admin] )
      user.transfer_requests_to( params[:wh_admin] )
      user.destroy
      render json: { success: 'Se ha eliminado el usuario y se ha transferido su inventario con éxito' }
      return
    end

    user.destroy
    render json: user, status: 200
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

  def get_delivery_users
  	respond_with User.delivery_users
  end

  def get_warehouse_admins
    respond_with User.warehouse_admins
  end

	private	

		def user_params
			params.require(:user).permit(:first_name, :last_name, :email, :password, :password_confirmation, :role, :avatar)
		end

		def user_password_params
			params.require(:user).permit(:password, :password_confirmation)
		end
end
