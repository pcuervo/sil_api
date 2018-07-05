module Api
  module V1
    class ItemLocationsController < ApplicationController
      respond_to :json

      def show
        respond_with ItemLocation.find(params[:id])
      end

      def index
        respond_with ItemLocation.all
      end

      def create
        if params[:inventory_item_id].nil? || params[:inventory_item_id].empty?
          render json: { errors: 'No se ha encontrado el artículo.' }, status: 422
          return
        end

        if params[:warehouse_location_id].nil? || params[:warehouse_location_id].empty?
          render json: { errors: 'No se ha encontrado la ubicación.' }, status: 422
          return
        end

        item_location = ItemLocation.new
        item_location.quantity = params[:quantity]
        inventory_item = InventoryItem.find(params[:inventory_item_id])
        warehouse_location = WarehouseLocation.find(params[:warehouse_location_id])

        inventory_item.item_locations << item_location
        warehouse_location.item_locations << item_location

        if item_location.save
          render json: item_location, status: 201, location: [:api, item_location]
          return
        end

        render json: { errors: item_location.errors }, status: 422
      end

      def details
        item_location = ItemLocation.where('inventory_item_id = ? AND warehouse_location_id = ?', params[:item_id], params[:location_id]).first

        if item_location.present?
          render json: item_location.details, status: 201, location: [:api, item_location]
          return
        end

        render json: { errors: 'No se pudo encontrar la ubicación.' }, status: 422
      end
    end
  end
end
