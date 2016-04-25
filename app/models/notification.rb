class Notification < ActiveRecord::Base
  has_and_belongs_to_many :users

  validates :title,   presence: true
  validates :message, presence: true

  UNREAD = 1
  READ = 2

  scope :unread_first, -> { order(status: :desc, created_at: :desc) }
  scope :unread, -> { where( status: UNREAD.to_i ).order(created_at: :desc) }
  scope :read, -> { where( status: READ.to_i ).order(created_at: :desc) }
end
