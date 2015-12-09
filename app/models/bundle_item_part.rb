class BundleItemPart < ActiveRecord::Base
  belongs_to :bundle_item

  validates :name, :serial_number, presence: true
  validates :serial_number, uniqueness: true
end
