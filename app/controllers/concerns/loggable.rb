module Loggable

  def log_action user_id, sys_module, action, actor_id
    log = Log.new(:user_id=> user_id, :sys_module=> sys_module, :action=> action, :actor_id => actor_id )

    return log.save
  end  

end