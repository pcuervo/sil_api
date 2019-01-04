# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ReplenishInventory, type: :class do
  let(:location) { FactoryBot.create(:warehouse_location) }

  describe 'ReplenishInventory.by_item' do
    context 'when successful' do
      let(:item) { FactoryBot.create(:inventory_item, quantity: 0) }
      let(:quantity){ 100 }
      let(:folio){ InventoryTransaction.next_checkin_folio }
      let(:replenisher){ ReplenishInventory.new([]) }

      it 'should clean history of an InventoryItem' do
        replenisher.by_item(item.id, quantity, location.name, 'Test carga CSV', folio)
        item.reload
        item_location = ItemLocation.find_by(inventory_item_id: item.id, warehouse_location_id: location.id)

        expect(item.quantity).to eq quantity
        expect(item_location.quantity).to eq quantity
        expect(CheckInTransaction.count).to eq 1
        expect(WarehouseTransaction.count).to eq 1
        expect(replenisher.processed).to eq 1
      end
    end

    context 'when not successful' do
      context 'InventoryItem does not exist' do
        let(:invalid_id) { -1 }
        let(:quantity){ 100 }
        let(:folio){ InventoryTransaction.next_checkin_folio }
        let(:replenisher){ ReplenishInventory.new([]) }

        it 'should skip item and store error' do
          replenisher.by_item(invalid_id, quantity, location.name, 'Test carga CSV', folio)
          errors = replenisher.errors
          
          expect(errors.count).to eq 1
          expect(errors.first).to eq 'No se pudo agregar el artículo con ID: -1'
          expect(replenisher.processed).to eq 0
        end
      end

      context 'WarehouseLocation does not exist' do
        let(:item) { FactoryBot.create(:inventory_item, quantity: 0) }
        let(:invalid_location){ 'invalid_location_name' }
        let(:quantity){ 100 }
        let(:folio){ InventoryTransaction.next_checkin_folio }
        let(:replenisher){ ReplenishInventory.new([]) }

        it 'should skip item and store error' do
          replenisher.by_item(item, quantity, invalid_location, 'Test carga CSV', folio)
          errors = replenisher.errors
          
          expect(errors.count).to eq 1
          expect(errors.first).to eq 'No se pudo encontrar la ubicación: invalid_location_name'
          expect(replenisher.processed).to eq 0
        end
      end

      context 'quantity less than 1' do
        let(:item) { FactoryBot.create(:inventory_item, quantity: 0) }
        let(:quantity){ 0 }
        let(:folio){ InventoryTransaction.next_checkin_folio }
        let(:replenisher){ ReplenishInventory.new([]) }

        it 'should skip item and store error' do
          replenisher.by_item(item.id, quantity, location.name, 'Test carga CSV', folio)
          errors = replenisher.errors
          
          expect(errors.count).to eq 1
          expect(errors.first).to eq "La cantidad el artículo con ID #{item.id} debe ser mayor que 0"
          expect(replenisher.processed).to eq 0
        end
      end
    end
  end

  describe 'ReplenishInventory.replenish' do
    context 'when successful' do
      let(:items) { FactoryBot.create_list(:inventory_item, 5, quantity: 0) }
      let(:quantity){ 50 }
      let(:item_data){ format_for_replenish(items, quantity, location) }
      let(:replenisher){ ReplenishInventory.new(item_data) }

      it 'should clean history of an InventoryItem' do
        replenisher.replenish

        expect(InventoryItem.first.quantity).to eq 50
        expect(InventoryItem.second.quantity).to eq 50
        expect(InventoryItem.third.quantity).to eq 50
        expect(InventoryItem.fourth.quantity).to eq 50
        expect(InventoryItem.fifth.quantity).to eq 50

        expect(CheckInTransaction.count).to eq 5
        expect(WarehouseTransaction.count).to eq 5
        expect(replenisher.processed).to eq 5
      end
    end

    context 'when not successful' do
      context 'InventoryItem does not exist' do
        let(:items) { FactoryBot.create_list(:inventory_item, 5, quantity: 0) }
        let(:quantity){ 50 }
        let(:item_data){ format_for_replenish(items, quantity, location) }
        let(:replenisher){ ReplenishInventory.new(item_data) }

        before do
          invalid_data = [-1, quantity, location.name]
          item_data.unshift(invalid_data)
        end

        it 'should skip item and store error' do
          replenisher.replenish
          errors = replenisher.errors
          
          expect(errors.count).to eq 1
          expect(errors.first).to eq 'No se pudo agregar el artículo con ID: -1'
          expect(replenisher.processed).to eq 5
        end
      end

      context 'WarehouseLocation does not exist' do
        let(:items) { FactoryBot.create_list(:inventory_item, 5, quantity: 0) }
        let(:quantity){ 50 }
        let(:item_data){ format_for_replenish(items, quantity, location) }
        let(:replenisher){ ReplenishInventory.new(item_data) }

        before do
          invalid_data = [items.first.id, items.first.name, quantity, 'INVALID_LOCATION']
          item_data.unshift(invalid_data)
        end

        it 'should skip item and store error' do
          replenisher.replenish
          errors = replenisher.errors
          
          expect(errors.count).to eq 1
          expect(errors.first).to eq 'No se pudo encontrar la ubicación: INVALID_LOCATION'
          expect(replenisher.processed).to eq 5
        end
      end

      context 'quantity is less than 1' do
        let(:items) { FactoryBot.create_list(:inventory_item, 5, quantity: 0) }
        let(:quantity){ 50 }
        let(:item_data){ format_for_replenish(items, quantity, location) }
        let(:replenisher){ ReplenishInventory.new(item_data) }

        before do
          invalid_data = [items.first.id, items.first.name, -1, location.name]
          item_data.unshift(invalid_data)
        end

        it 'should skip item and store error' do
          replenisher.replenish
          errors = replenisher.errors

          expect(errors.count).to eq 1
          expect(errors.first).to eq "La cantidad el artículo con ID #{items.first.id} debe ser mayor que 0"
          expect(replenisher.processed).to eq 5
        end
      end
    end
  end
end
