module Loggable

  def log_action user_id, sys_module, action, actor_id
    Log.create!(:user_id=> user_id, :sys_module=> sys_module, :action=> action, :actor_id => actor_id )
  end  

end