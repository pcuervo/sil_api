class Log < ActiveRecord::Base

  validates :sys_module, :action, :actor_id, presence: true

  belongs_to :user

end
