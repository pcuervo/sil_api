# frozen_string_literal: true

class InventoryCleaner
  # Remove history of an InventoryItem and reset quantity to zero.
  def self.by_inventory_item(item)
    item.withdraw(Date.today, '', '', '', '', item.quantity)

    item.delete_transactions
    item.delete_warehouse_transactions
    item.delete_item_locations
    item.delete_pm_items
    item.delete_ae_items
  end

  # Reset Inventory by Project
  def self.by_project(project)
    project.inventory_items.each { |item| InventoryCleaner.by_inventory_item(item) }
  end
end
