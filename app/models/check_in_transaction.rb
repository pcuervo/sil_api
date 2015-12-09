class CheckInTransaction < ActiveRecord::Base
  acts_as :inventory_transaction

  validates :entry_date, presence: true

end
