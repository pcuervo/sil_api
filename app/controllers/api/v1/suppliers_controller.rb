module Api
  module V1
    class SuppliersController < ApplicationController
      before_action only: %i[update create destroy] do
        authenticate_with_token! request.headers['Authorization']
      end
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
          render json: supplier, status: 201, location: [:api, supplier]
          return
        end

        render json: { errors: supplier.errors }, status: 422
      end

      def update
        supplier = Supplier.find(params[:id])

        if supplier.update(supplier_params)
          render json: supplier, status: 201, location: [:api, supplier]
          return
        end

        render json: { errors: supplier.errors }, status: 422
      end

      def destroy
        supplier = Supplier.find(params[:id])
        supplier.destroy
        head 204
      end

      private

      def supplier_params
        params.require(:supplier).permit(:name)
      end
    end
  end
end
