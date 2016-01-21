class Api::V1::SuppliersController < ApplicationController
  before_action :authenticate_with_token!, only: [:update, :create, :destroy]
  respond_to :json

  def show
    respond_with Supplier.find(params[:id])
  end

  def index
    respond_with Supplier.order(created_at: :desc).all
  end

  def create
    supplier = Supplier.new(supplier_params)
    if supplier.save
      log_action( current_user.id, 'Supplier', 'Created supplier: "' + supplier.name, supplier.id )
      render json: supplier, status: 201, location: [:api, supplier]
      return
    end

    render json: { errors: supplier.errors }, status: 422
  end

  def update
    supplier = Supplier.find(params[:id])

    if supplier.update(supplier_params) 
      log_action( current_user.id, 'Supplier', 'Updated supplier: "' + supplier.name, supplier.id )
      render json: supplier, status: 201, location: [:api, supplier ]
      return
    end

    render json: { errors: supplier.errors }, status: 422
  end

  def destroy
    supplier = Supplier.find(params[:id])
    supplier.destroy
    log_action( current_user.id, 'Supplier', 'Deleted supplier: "' + supplier.name, supplier.id )
    head 204
  end

  private

  def supplier_params
    params.require(:supplier).permit(:name)
  end
end
