class Client < ActiveRecord::Base
  has_many :projects

  validates :name, presence: true
  validates :name, uniqueness: true
end
