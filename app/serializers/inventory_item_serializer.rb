class InventoryItemSerializer < ActiveModel::Serializer
  attributes :id, :name, :item_type, :actable_type, :validity_expiration_date, :status, :value, :created_at, :item_img_thumb, :quantity, :project_data, :owner, :serial_number, :brand, :model, :extra_parts, :barcode

  def item_img_thumb
    object.item_img(:medium)
  end

  def project_data
    return if object.project_id.nil?
    
    project_data = {}
    project = Project.find( object.project_id )
    project_data[:litobel_id] = project.litobel_id
    project_data[:name] = project.name
    project_data[:ae] = project.ae_name
    project_data[:client] = project.client
    project_data
  end

  def owner
    user = object.user
    user.first_name + ' ' + user.last_name
  end
end
