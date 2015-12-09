class Api::V1::ClientsController < ApplicationController
  before_action :authenticate_with_token!, only: [:update, :create, :destroy]
  respond_to :json

  def show
    respond_with Client.find(params[:id])
  end

  def index
    respond_with Client.order(created_at: :desc).all
  end

  def create
    client = Client.new(client_params)
    if client.save
      log_action( current_user.id, 'Client', 'Created client: "' + client.name, client.id )
      render json: client, status: 201, location: [:api, client]
      return
    end

    render json: { errors: client.errors }, status: 422
  end

  def update
    client = Client.find(params[:id])

    if client.update(client_params) 
      log_action( current_user.id, 'Client', 'Updated client: "' + client.name, client.id )
      render json: client, status: 201, location: [:api, client ]
      return
    end

    render json: { errors: client.errors }, status: 422
  end

  def destroy
    client = Client.find(params[:id])
    client.destroy
    log_action( current_user.id, 'Client', 'Deleted client: "' + client.name, client.id )
    head 204
  end

  private

  def client_params
    params.require(:client).permit(:name)
  end
end
