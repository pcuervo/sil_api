class PmItem < ActiveRecord::Base
  self.table_name = 'pm_items'
  
  has_many :inventory_items
  has_many :users
end
