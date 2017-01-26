class AeItem < ActiveRecord::Base
  self.table_name = 'ae_items'
  
  belongs_to :inventory_item
  belongs_to :user
end
