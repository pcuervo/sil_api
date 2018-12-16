# frozen_string_literal: true

require 'spec_helper'

RSpec.describe InventoryCleaner, type: :class do
  let(:project){ FactoryBot.create(:project) }

  describe 'InventoryCleaner.by_inventory_item' do
    let(:item) { create_item_with_location(100, project) }

    it 'should clean history of an InventoryItem' do
      InventoryCleaner.by_inventory_item(item)
      item.reload

      expect(item.quantity).to eq 0
      expect(CheckInTransaction.count).to eq 0
      expect(CheckOutTransaction.count).to eq 0
      expect(ItemLocation.count).to eq 0
      expect(WarehouseTransaction.count).to eq 0
    end
  end

  describe 'InventoryCleaner.by_project' do
    let(:item) { 10.times { create_item_with_location(100, project) } }

    it 'should clean history of a Project' do
      InventoryCleaner.by_project(project)
      project.reload

      expect(project.inventory_items.count).to eq 0
      expect(CheckInTransaction.count).to eq 0
      expect(CheckOutTransaction.count).to eq 0
      expect(ItemLocation.count).to eq 0
      expect(WarehouseTransaction.count).to eq 0
    end
  end
end
