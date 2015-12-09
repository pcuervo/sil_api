class UnitItem < ActiveRecord::Base
  acts_as :inventory_item

  validates :serial_number, presence: true
  validates :serial_number, uniqueness: true
end
