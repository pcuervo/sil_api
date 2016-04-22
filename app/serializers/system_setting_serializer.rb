class SystemSettingSerializer < ActiveModel::Serializer
  attributes :id, :units_per_location, :cost_per_location, :cost_high_value
end
