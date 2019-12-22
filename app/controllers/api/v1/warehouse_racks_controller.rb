module Api
  module V1
    class WarehouseRacksController < ApplicationController
      respond_to :json

      def index
        respond_with WarehouseRack.more_info
      end

      def show
        respond_with WarehouseRack.find(params[:id])
      end

      def show_details
        rack = WarehouseRack.find(params[:id])
        rack.update_locations
        respond_with rack.details
      end

      def available_locations
        rack = WarehouseRack.find(params[:id])
        respond_with rack.available_locations
      end

      def create
        warehouse_rack = WarehouseRack.new(warehouse_rack_params)

        if warehouse_rack.save
          warehouse_rack.add_initial_locations(params[:quantity].to_i)
          render json: warehouse_rack, status: 201, location: [:api, warehouse_rack]
          return
        end

        render json: { errors: warehouse_rack.errors }, status: 422
      end

      def items
        rack = WarehouseRack.find(params[:id])
        respond_with rack.items
      end

      def destroy
        rack = WarehouseRack.find(params[:id])
        if rack.empty?
          rack.warehouse_locations.each do |l|
            l.warehouse_transactions.destroy_all
            l.destroy
          end
          rack.destroy
          head 204
          return
        end
        render json: { errors: 'No se puede eliminar un rack con ubicaciones ocupadas' }, status: 422
      end

      def stats
        stats = {}

        total_racks = WarehouseRack.all.count
        total_locations = WarehouseLocation.all.count
        total_items_in_warehouse = ItemLocation.select('inventory_item_id').distinct.count
        total_occupied_locations = ItemLocation.select('warehouse_location_id').distinct.count
        total_items_with_pending_location =
          InventoryItem.joins('LEFT JOIN item_locations ON inventory_items.id = item_locations.inventory_item_id ').where(
            ' item_locations.id is null AND inventory_items.status IN (?)',
            [InventoryItem::IN_STOCK,
             InventoryItem::PARTIAL_STOCK]
          ).count
        total_items_with_pending_reentry_location =
          InventoryItem.select(
            'inventory_items.id, SUM(item_locations.quantity) AS quantity_locations, SUM(bulk_items.quantity) AS quantity_bulk'
          ).joins(:item_locations).joins(
            'INNER JOIN bulk_items ON bulk_items.id = inventory_items.actable_id'
          ).where('actable_type = ?', 'BulkItem').group('inventory_items.id, bulk_items.quantity').having(
            'SUM(item_locations.quantity) < bulk_items.quantity'
          ).pluck('inventory_items.id').count

        warehouse_occupation_percentage = (total_occupied_locations.to_i / total_locations.to_f * 100).round

        stats['total_racks'] = total_racks
        stats['total_locations'] = total_locations
        stats['total_occupied_locations'] = total_occupied_locations
        stats['total_items_in_warehouse'] = total_items_in_warehouse
        stats['total_items_with_pending_location'] = total_items_with_pending_location + total_items_with_pending_reentry_location
        stats['warehouse_occupation_percentage'] = warehouse_occupation_percentage
        stats['current_month_rent'] = 0

        render json: { stats: stats }, status: 200
      end

      def empty
        warehouse_rack = WarehouseRack.find(params[:id])

        if warehouse_rack.empty
          render json: { success: 'El rack fue vaciado correctamente.' }, status: 201, location: [:api, warehouse_rack]
          return
        end

        render json: { errors: 'No se pudo vaciar el rack.' }, status: 201
      end

      private

      def warehouse_rack_params
        params.require(:warehouse_rack).permit(:name, :row, :column)
      end
    end
  end
end
