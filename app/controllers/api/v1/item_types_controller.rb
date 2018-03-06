class Api::V1::ItemTypesController < ApplicationController
  before_action only: [:create] do 
    authenticate_with_token! request.headers['Authorization']
  end

  respond_to :json

  def index
    respond_with ItemType.all.order(:name)
  end

  def show
    if ! ItemType.exists?( params[:id] )
      render json: { errors: "No se encontró el tipo de mercancía." }, status: 422
      return
    end
    respond_with ItemType.find( params[:id] )
  end

  def create
    item_type = ItemType.new(item_type_params)

    if item_type.save
      render json: item_type, status: 201, location: [:api, item_type]
      return
    end

    render json: { errors: item_type.errors }, status: 422
  end

  private

    def item_type_params
      params.require(:item_type).permit(:name)
    end

end
