class ItemLocation < ActiveRecord::Base
  belongs_to :inventory_item
  belongs_to :warehouse_location
end
