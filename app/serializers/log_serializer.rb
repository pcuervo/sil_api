class LogSerializer < ActiveModel::Serializer
  attributes :id, :user, :sys_module, :action, :actor_id, :created_at
end
