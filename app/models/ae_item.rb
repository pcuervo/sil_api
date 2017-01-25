class AeItem < ActiveRecord::Base
  self.table_name = 'ae_items'
  
  has_many :inventory_items
  has_many :users
end
