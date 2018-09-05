class CheckInTransaction < ActiveRecord::Base
  acts_as :inventory_transaction

  validates :entry_date, presence: true

  scope :latest, ->(num) { where('folio != ?', '-').order(folio: :desc).limit(num) }
end
