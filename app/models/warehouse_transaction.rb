class WarehouseTransaction < ActiveRecord::Base
  belongs_to :inventory_item
  belongs_to :warehouse_location

  # Transaction Concepts
  ENTRY = 1
  MOVE = 2
  WITHDRAW = 3
end
