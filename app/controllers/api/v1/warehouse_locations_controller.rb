module Api
  module V1
    class WarehouseLocationsController < ApplicationController
      require 'csv'

      before_action only: %i[update locate_item csv_locate] do
        authenticate_with_token! request.headers['Authorization']
      end
      respond_to :json

      def show
        respond_with WarehouseLocation.find(params[:id]).get_details
      end

      def index
        respond_with WarehouseLocation.all
      end

      def update
        warehouse_location = WarehouseLocation.find(params[:id])

        if warehouse_location.update(warehouse_location_params)
          render json: warehouse_location, status: 200, location: [:api, warehouse_location]
        else
          render json: { errors: warehouse_location.errors }, status: 422
        end
      end

      def locate_item
        inventory_item = InventoryItem.find(params[:inventory_item_id])

        location = WarehouseLocation.find(params[:warehouse_location_id])
        new_location_id = location.locate(inventory_item, params[:quantity].to_i)

        if new_location_id > 0
          item_location = ItemLocation.find(new_location_id)
          render json: item_location, status: 201, location: [:api, item_location]
          return
        end

        render json: { errors: 'No se pudo ubicar el artículo' }, status: 422
      end

      def locate_bulk
        inventory_item = InventoryItem.find(params[:inventory_item_id])
        bulk_locations = params[:bulk_locations]
        locations = []

        bulk_locations.each do |bl|
          location = WarehouseLocation.find(bl[:locationId])
          new_location_id = location.locate(inventory_item, bl[:quantity])
          if new_location_id > 0
            locations.push(ItemLocation.find(new_location_id))
            next
          end

          render json: { errors: 'No se pudo ubicar el artículo' }, status: 422
          return
        end

        render json: { item_locations: locations }, status: 201
      end

      def relocate_item
        inventory_item = InventoryItem.find(params[:inventory_item_id])
        old_location = WarehouseLocation.find(params[:old_location_id])
        new_location = WarehouseLocation.find(params[:new_location_id])
        quantity = params[:quantity].to_i

        old_location.relocate(inventory_item, quantity, new_location)
        item_location = ItemLocation.find_by(
          inventory_item_id: inventory_item.id,
          warehouse_location_id: new_location.id
        )

        unless item_location.nil?
          render json: item_location, status: 201, location: [:api, item_location]
          return
        end

        render json: { errors: 'No se pudo ubicar el artículo, la ubicación "' + location.name + '" se encuentra llena.' }, status: 422
      rescue StandardError => e
        render json: { errors: e.message }, status: 422
      end

      def mark_as_full
        location = WarehouseLocation.find(params[:location_id])
        location.mark_as_full
        render json: { success: 'Ubiación marcada como llena.' }, status: 200
      end

      def mark_as_available
        location = WarehouseLocation.find(params[:location_id])
        location.mark_as_available
        render json: { success: 'Ubiación marcada como disponible.' }, status: 200
      end

      def csv_locate
        warehouse_update = WarehouseLocation.bulk_locate(current_user.email, params[:warehouse_data])
        if warehouse_update[:errors].count.zero?
          render json: { success: 'Los artículos se ubicaron correctamente.' }, status: 200
          return
        end

        render json: { errors: warehouse_update[:errors], located_items: warehouse_update[:located_items] }, status: 200
      end

      private

      def warehouse_location_params
        params.require(:warehouse_location).permit(:name, :quantity)
      end
    end
  end
end
