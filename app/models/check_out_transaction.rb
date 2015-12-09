class CheckOutTransaction < ActiveRecord::Base
  acts_as :inventory_transaction
  
  validates :exit_date, presence: true
end
