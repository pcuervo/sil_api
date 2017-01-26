class PmItem < ActiveRecord::Base
  self.table_name = 'pm_items'
  
  belongs_to :inventory_item
  belongs_to :user
end
