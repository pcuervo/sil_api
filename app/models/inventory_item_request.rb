class InventoryItemRequest < ActiveRecord::Base
  validates :name, :project_id, :pm_id, :ae_id, :item_type, presence: true

  def self.details
    inventory_item_requests_details = { 'inventory_item_requests' => [] }
    InventoryItemRequest.all.each do |i|
      project = Project.find(i.project_id)
      pm = User.find(i.pm_id.to_i)
      ae = User.find(i.ae_id)
      inventory_item_requests_details['inventory_item_requests'].push(
        'id' => i.id,
        'name'                      => i.name,
        'item_type'                 => i.item_type,
        'quantity'                  => i.quantity,
        'description'               => i.description,
        'project_id'                => i.project_id,
        'project'                   => project.name,
        'pm_id'                     => i.pm_id,
        'pm'                        => pm.first_name + ' ' + pm.last_name,
        'ae_id'                     => i.ae_id,
        'ae'                        => ae.first_name + ' ' + ae.last_name,
        'entry_date'                => i.entry_date,
        'state'                     => i.state,
        'validity_expiration_date'  => i.validity_expiration_date
      )
    end
    inventory_item_requests_details
  end

  def cancel
    destroy
  end
end
