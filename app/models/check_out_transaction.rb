class CheckOutTransaction < ActiveRecord::Base
  acts_as :inventory_transaction
  
  validates :exit_date, presence: true

  scope :latest, ->(num) { where('folio != ?', '-').order(folio: :desc).limit(num) }
end
