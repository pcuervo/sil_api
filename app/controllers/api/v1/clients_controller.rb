class Api::V1::ClientsController < ApplicationController
  before_action only: [:update, :create, :destroy] do 
    authenticate_with_token! request.headers['Authorization']
  end
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
      render json: client, status: 201, location: [:api, client]
      return
    end

    render json: { errors: client.errors }, status: 422
  end

  def update
    client = Client.find(params[:id])

    if client.update(client_params) 
      render json: client, status: 201, location: [:api, client ]
      return
    end

    render json: { errors: client.errors }, status: 422
  end

  def destroy
    client = Client.find(params[:id])
    client.destroy
    head 204
  end

  private

  def client_params
    params.require(:client).permit(:name)
  end
end
