class ClientContact < ActiveRecord::Base
  acts_as :user
  belongs_to :client

  validates :client, presence: true
end
