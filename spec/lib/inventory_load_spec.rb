# frozen_string_literal: true

require 'spec_helper'

RSpec.describe InventoryLoad, type: :class do
  let(:location) { FactoryBot.create(:warehouse_location) }

  describe 'InventoryLoad.create_item' do
    context 'when successful' do
      let(:num_items){ 1 }
      let(:user){ FactoryBot.create(:user) }
      let(:item_data) { csv_load_attributes(num_items).first }
      let(:folio){ InventoryTransaction.next_checkin_folio }
      let(:item_loader){ InventoryLoad.new(user, item_data) }

      it 'should add a new InventoryItem' do
        item_loader.create_item(item_data, folio)
        item = InventoryItem.first
        location = WarehouseLocation.first
        item_location = ItemLocation.find_by(inventory_item_id: item.id, warehouse_location_id: location.id)

        expect(item.quantity).to eq 1
        expect(item_location.quantity).to eq 1
        expect(CheckInTransaction.count).to eq 1
        expect(WarehouseTransaction.count).to eq 1
        expect(item_loader.processed).to eq 1
        expect(item_loader.errors.count).to eq 0
      end
    end

    context 'when not successful' do
      context 'Project does not exist' do
        let(:project_index){ 0 }
        let(:num_items){ 1 }
        let(:user){ FactoryBot.create(:user) }
        let(:item_data) { csv_load_attributes(num_items).first }
        let(:folio){ InventoryTransaction.next_checkin_folio }
        before { item_data[project_index] = 'INVALID_PROJECT' }
        let(:item_loader){ InventoryLoad.new(user, item_data) }

        it 'should return error' do
          item_loader.create_item(item_data, folio)
          errors = item_loader.errors
          
          expect(errors.count).to eq 1
          expect(errors.first).to eq 'No se encontró el proyecto: INVALID_PROJECT'
          expect(item_loader.processed).to eq 0
        end
      end

      context 'Client does not exist' do
        let(:client_index){ 1 }
        let(:num_items){ 1 }
        let(:user){ FactoryBot.create(:user) }
        let(:item_data) { csv_load_attributes(num_items).first }
        let(:folio){ InventoryTransaction.next_checkin_folio }
        before { item_data[client_index] = 'INVALID_CLIENT' }
        let(:item_loader){ InventoryLoad.new(user, item_data) }

        it 'should return error' do
          item_loader.create_item(item_data, folio)
          errors = item_loader.errors
          
          expect(errors.count).to eq 1
          expect(errors.first).to eq 'No se encontró el cliente: INVALID_CLIENT'
          expect(item_loader.processed).to eq 0
        end
      end

      context 'Invalid quantity' do
        let(:name_index){ 2 }
        let(:quantity_index){ 3 }
        let(:num_items){ 1 }
        let(:user){ FactoryBot.create(:user) }
        let(:item_data) { csv_load_attributes(num_items).first }
        let(:folio){ InventoryTransaction.next_checkin_folio }
        before { item_data[quantity_index] = 0 }
        let(:item_loader){ InventoryLoad.new(user, item_data) }

        it 'should return error' do
          item_loader.create_item(item_data, folio)
          errors = item_loader.errors
          
          expect(errors.count).to eq 1
          expect(errors.first).to eq "La cantidad del artículo #{item_data[name_index]} debe ser mayor que 0"
          expect(item_loader.processed).to eq 0
        end
      end

      context 'WarehouseLocation does not exist' do
        let(:location_index){ 11 }
        let(:num_items){ 1 }
        let(:user){ FactoryBot.create(:user) }
        let(:item_data) { csv_load_attributes(num_items).first }
        let(:folio){ InventoryTransaction.next_checkin_folio }
        before { item_data[location_index] = 'INVALID_LOCATION' }
        let(:item_loader){ InventoryLoad.new(user, item_data) }

        it 'should return error' do
          item_loader.create_item(item_data, folio)
          errors = item_loader.errors
          
          expect(errors.count).to eq 1
          expect(errors.first).to eq 'No se pudo encontrar la ubicación: INVALID_LOCATION'
          expect(item_loader.processed).to eq 0
        end
      end
    end
  end

  describe 'InventoryLoad.generate_barcode' do
    let(:num_items){ 1 }
    let(:user){ FactoryBot.create(:user) }
    let(:item_data) { csv_load_attributes(num_items).first }
    let(:item_loader){ InventoryLoad.new(user, item_data) }
    let(:project){ 'My-Project' }
    let(:item){ 'AwesomeItem' }
    let(:item_type){ 'Laptop' }

    it 'should return a barcode' do
      barcode = item_loader.generate_barcode(project, item, item_type)

      expect(barcode.length).to eq 18
    end
  end
  
  describe 'InventoryLoad.load' do
    context 'when successful' do
      let(:num_items){ 5 }
      let(:user){ FactoryBot.create(:user) }
      let(:item_data) { csv_load_attributes(num_items) }
      let(:item_loader){ InventoryLoad.new(user, item_data) }

      it 'should clean history of an InventoryItem' do
        item_loader.load

        expect(InventoryItem.first.quantity).to eq 1
        expect(InventoryItem.second.quantity).to eq 1
        expect(InventoryItem.third.quantity).to eq 1
        expect(InventoryItem.fourth.quantity).to eq 1
        expect(InventoryItem.fifth.quantity).to eq 1

        expect(CheckInTransaction.count).to eq 5
        expect(WarehouseTransaction.count).to eq 5
        expect(item_loader.processed).to eq 5
      end
    end

    context 'when not successful' do
      context 'A Project does not exist' do
        let(:project_index){ 0 }
        let(:num_items){ 5 }
        let(:user){ FactoryBot.create(:user) }
        let(:item_data) { csv_load_attributes(num_items) }
        let(:item_loader){ InventoryLoad.new(user, item_data) }

        before{ item_data.first[project_index] = 'INVALID_PROJECT' }

        it 'should skip item and store error' do
          item_loader.load
          errors = item_loader.errors
          
          expect(errors.count).to eq 1
          expect(errors.first).to eq 'No se encontró el proyecto: INVALID_PROJECT'
          expect(item_loader.processed).to eq 4
          expect(InventoryItem.count).to eq 4
        end
      end
    end
  end

  #     context 'WarehouseLocation does not exist' do
  #       let(:items) { FactoryBot.create_list(:inventory_item, 5, quantity: 0) }
  #       let(:quantity){ 50 }
  #       let(:item_data){ format_for_replenish(items, quantity, location) }
  #       let(:replenisher){ InventoryLoad.new(item_data) }

  #       before do
  #         invalid_data = [items.first.id, items.first.name, quantity, 'INVALID_LOCATION']
  #         item_data.unshift(invalid_data)
  #       end

  #       it 'should skip item and store error' do
  #         replenisher.replenish
  #         errors = replenisher.errors
          
  #         expect(errors.count).to eq 1
  #         expect(errors.first).to eq 'No se pudo encontrar la ubicación: INVALID_LOCATION'
  #         expect(replenisher.processed).to eq 5
  #       end
  #     end

  #     context 'quantity is less than 1' do
  #       let(:items) { FactoryBot.create_list(:inventory_item, 5, quantity: 0) }
  #       let(:quantity){ 50 }
  #       let(:item_data){ format_for_replenish(items, quantity, location) }
  #       let(:replenisher){ InventoryLoad.new(item_data) }

  #       before do
  #         invalid_data = [items.first.id, items.first.name, -1, location.name]
  #         item_data.unshift(invalid_data)
  #       end

  #       it 'should skip item and store error' do
  #         replenisher.replenish
  #         errors = replenisher.errors

  #         expect(errors.count).to eq 1
  #         expect(errors.first).to eq "La cantidad el artículo con ID #{items.first.id} debe ser mayor que 0"
  #         expect(replenisher.processed).to eq 5
  #       end
  #     end
  #   end
  # end
end
