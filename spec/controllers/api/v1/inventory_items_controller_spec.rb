# frozen_string_literal: true

require 'spec_helper'

describe Api::V1::InventoryItemsController do
  describe 'GET #show' do
    before(:each) do
      @inventory_item = create_item_with_location
      get :show, params: { id: @inventory_item.id }
    end

    it 'returns the information about an inventory item on a hash' do
      inventory_item_response = json_response[:inventory_item]
      expect(inventory_item_response[:name]).to eql @inventory_item.name
      expect(inventory_item_response).to have_key(:locations)
    end

    it { should respond_with 200 }
  end

  describe 'GET #index' do
    before(:each) do
      5.times { FactoryBot.create :inventory_item }
      get :index
    end

    it 'returns 5 inventory items from the database' do
      inventory_items_response = json_response[:inventory_items]

      expect(inventory_items_response.size).to eq(5)
    end

    it { should respond_with 200 }
  end

  describe 'POST #create' do
    context 'when is succesfully created' do

      before(:each) do
        @folio = InventoryTransaction.next_checkin_folio
        user = FactoryBot.create :user
        project = FactoryBot.create :project
        client = FactoryBot.create :client

        @inventory_item_attributes = FactoryBot.attributes_for :inventory_item
        @inventory_item_attributes[:project_id] = project.id
        @inventory_item_attributes[:client_id] = client.id

        api_authorization_header user.auth_token
        post :create, params: { user_id: user.id, inventory_item: @inventory_item_attributes, item_img_ext: 'jpg', entry_date: Date.today }
      end

      it 'renders the json representation for the inventory item just created' do
        inventory_item_response = json_response[:inventory_item]
        expect(inventory_item_response[:name]).to eql @inventory_item_attributes[:name]
        expect(inventory_item_response[:brand]).to eql @inventory_item_attributes[:brand]
        expect(inventory_item_response[:model]).to eql @inventory_item_attributes[:model]
        expect(inventory_item_response[:quantity]).to eql @inventory_item_attributes[:quantity]
      end

      it 'should automatically add a transaction folio' do
        last_transaction = CheckInTransaction.last

        expect(last_transaction.folio).to eq @folio
      end

      it { should respond_with 201 }
    end

    context 'when is not created' do
      before(:each) do
        user = FactoryBot.create :user
        @invalid_inventory_item_attributes = { user_id: user.id }

        api_authorization_header user.auth_token
        post :create, params: { user_id: user.id, inventory_item: @invalid_inventory_item_attributes, item_img_ext: 'jpg' }
      end

      it 'renders an errors json' do
        inventory_item_response = json_response
        expect(inventory_item_response).to have_key(:errors)
      end

      it 'renders the json errors on why the inventory item could not be created' do
        inventory_item_response = json_response

        expect(inventory_item_response[:errors][:name]).to include 'El nombre no puede estar vacío'
      end

      it { should respond_with 422 }
    end
  end

  describe 'GET #authorize_entry' do
    before(:each) do
      @admin = FactoryBot.create :user
      @admin.role = User::ADMIN
      @admin.save
      @wh_admin = FactoryBot.create :user
      @wh_admin.role = User::WAREHOUSE_ADMIN
      @wh_admin.save

      project = FactoryBot.create :project

      @item = FactoryBot.create :inventory_item
      @item.status = InventoryItem::PENDING_ENTRY
      @item.project_id = project.id
      @item.save

      api_authorization_header @admin.auth_token
      post :authorize_entry, params: { id: @item.id }
    end

    it 'returns a success message' do
      inventory_item_response = json_response
      expect(inventory_item_response).to have_key(:success)
    end

    it 'should notify Admin' do
      admin = User.find_by_role(User::ADMIN)
      notification = admin.notifications.first
      inventory_item = InventoryItem.find(notification.inventory_item_id)
      expect(inventory_item.name).to eq @item.name
    end

    it 'should notify WarehouseAdmin' do
      wh_admin = User.find_by_role(User::WAREHOUSE_ADMIN)
      notification = wh_admin.notifications.first
      inventory_item = InventoryItem.find(notification.inventory_item_id)
      expect(inventory_item.name).to eq @item.name
    end

    it { should respond_with 201 }
  end

  describe 'POST #multiple_withdrawal' do
    context 'when multiple InventoryItems with location are succesfully withdrawn' do
      before(:each) do
        user = FactoryBot.create :user
        supplier = FactoryBot.create :supplier

        inventory_items = []
        3.times do |_t|
          inventory_item = create_item_with_location

          item_info = {}
          item_info[:id] = inventory_item.id
          item_info[:quantity] = inventory_item.quantity
          inventory_items.push(item_info)
        end

        api_authorization_header user.auth_token
        post :multiple_withdrawal, params: { inventory_items: inventory_items, exit_date: Time.now, estimated_return_date: Time.now + 10.days, delivery_company: supplier.id, delivery_company_contact: 'John Doe', additional_comments: 'This is just a test' }
      end

      it 'returns the number of withdrawn items along with success message' do
        inventory_item_response = json_response
        expect(inventory_item_response[:items_withdrawn]).to eql 3
        expect(inventory_item_response).to have_key(:success)
        expect(WarehouseTransaction.all.count).to eql 3
      end

      it 'withdraws all existing items from system' do
        expect(InventoryItem.where('status = ?', InventoryItem::OUT_OF_STOCK).count).to eq 3
      end

      it { should respond_with 201 }
    end

    context 'when multiple InventoryItems with location are partially withdrawn' do
      before(:each) do
        user = FactoryBot.create :user
        supplier = FactoryBot.create :supplier

        inventory_items = []
        3.times do |_t|
          inventory_item = create_item_with_location

          item_info = {}
          item_info[:id] = inventory_item.id
          item_info[:quantity] = inventory_item.quantity.to_i - 5
          inventory_items.push(item_info)
        end

        api_authorization_header user.auth_token
        post :multiple_withdrawal, params: { inventory_items: inventory_items, exit_date: Time.now, estimated_return_date: Time.now + 10.days, delivery_company: supplier.id, delivery_company_contact: 'John Doe', additional_comments: 'This is just a test' }
      end

      it 'returns the number of withdrawn items along with success message' do
        inventory_item_response = json_response
        expect(inventory_item_response[:items_withdrawn]).to eql 3
        expect(inventory_item_response).to have_key(:success)
        expect(WarehouseTransaction.all.count).to eql 3
      end

      it "doesn't withdraw all existing items from system" do
        expect(InventoryItem.where('status = ?', InventoryItem::IN_STOCK).count).to eq 3
      end

      it { should respond_with 201 }
    end

    context 'when multiple InventoryItems could not be withdrawn' do
      before(:each) do
        user = FactoryBot.create :user
        supplier = FactoryBot.create :supplier

        inventory_items = []
        3.times do
          inventory_item = FactoryBot.create :inventory_item
          warehouse_location = FactoryBot.create :warehouse_location
          item_location = FactoryBot.create :item_location
          inventory_item.item_locations << item_location
          warehouse_location.item_locations << item_location
          inventory_item.status = InventoryItem::OUT_OF_STOCK
          inventory_item.save

          item_info = {}
          item_info[:id] = inventory_item.id
          item_info[:quantity] = inventory_item.quantity
          inventory_items.push(item_info)
        end

        api_authorization_header user.auth_token
        post :multiple_withdrawal, params: { inventory_items: inventory_items, exit_date: Time.now, estimated_return_date: Time.now + 10.days, delivery_company: supplier.id, delivery_company_contact: 'John Doe', additional_comments: 'This is just a test' }
      end

      it 'returns the number of withdrawn items along with success message' do
        inventory_item_response = json_response
        expect(inventory_item_response[:items_withdrawn]).to eql 0
        expect(inventory_item_response).to have_key(:errors)
        expect(WarehouseTransaction.all.count).to eql 0
      end

      it { should respond_with 422 }
    end
  end

  describe 'POST #request_item_entry' do
    context 'when is succesfully requested' do
      before(:each) do
        @admin = FactoryBot.create :user
        @admin.role = User::ADMIN
        @admin.save
        @warehouse_admin = FactoryBot.create :user
        @warehouse_admin.role = User::WAREHOUSE_ADMIN
        @warehouse_admin.save

        user = FactoryBot.create :user
        @requested_item_attributes = FactoryBot.attributes_for :inventory_item_request

        api_authorization_header user.auth_token
        post :request_item_entry, params: { inventory_item_request: @requested_item_attributes }
      end

      it 'renders the json representation for the inventory item just requested' do
        inventory_item_response = json_response[:inventory_item]
        expect(inventory_item_response[:name]).to eql @requested_item_attributes[:name]
      end

      it 'send Notification to Admin and WarehouseAdmin' do
        notification = @admin.notifications.first
        expect(notification.title).to eql 'Solicitud de entrada'
      end

      it { should respond_with 201 }
    end
  end

  describe 'GET #pending_entry_requests' do
    context 'when is succesfully requested' do
      before(:each) do
        user = FactoryBot.create :user

        project = FactoryBot.create :project
        ae = FactoryBot.create :user
        pm = FactoryBot.create :user
        3.times.each do
          item_request = FactoryBot.create :inventory_item_request
          item_request.project_id = project.id
          item_request.pm_id = pm.id
          item_request.ae_id = ae.id
          item_request.save
        end

        api_authorization_header user.auth_token
        get :pending_entry_requests
      end

      it 'returns all the InventoryItemRequests' do
        inventory_item_response = json_response[:inventory_item_requests]
        expect(inventory_item_response.count).to eql 3
      end

      it { should respond_with 200 }
    end
  end

  # Helpers to create and setup tests.
  def create_item_with_location
    inventory_item = FactoryBot.create :inventory_item
    warehouse_location = FactoryBot.create :warehouse_location
    ItemLocation.create(inventory_item_id: inventory_item.id, warehouse_location_id: warehouse_location.id, quantity: inventory_item.quantity)

    inventory_item
  end

  describe 'POST #update' do
    context 'when InventoryItem is successfully updated' do
      let(:user) { FactoryBot.create(:user) }
      let(:inventory_item) { FactoryBot.create(:inventory_item) }
      before(:each) do
        api_authorization_header user.auth_token

        post :update, {
          params: {
            id: inventory_item.id,
            inventory_item: {
              name: 'My new name',
              serial_number: 'OTHER123',
              brand: 'NewBrand',
              model: 'NewModel',
              state: 2,
              value: 2000.0,
              description: 'A new description',
              extra_parts: 'Part 1, part 2, part3',
              storage_type: 'Temporal',
              validity_expiration_date: '2059-07-14'
            }
          }
        }, format: :json
      end

      it 'renders the json representation for the updated InventoryItem' do
        bulk_item_response = json_response[:inventory_item]
        expect(bulk_item_response[:name]).to eql 'My new name'
        expect(bulk_item_response[:serial_number]).to eql 'OTHER123'
        expect(bulk_item_response[:brand]).to eql 'NewBrand'
        expect(bulk_item_response[:model]).to eql 'NewModel'
        expect(bulk_item_response[:state]).to eql 2
        expect(bulk_item_response[:value]).to eql '2000.0'
        expect(bulk_item_response[:description]).to eql 'A new description'
        expect(bulk_item_response[:extra_parts]).to eql 'Part 1, part 2, part3'
        expect(bulk_item_response[:storage_type]).to eql 'Temporal'
        expect(bulk_item_response[:validity_expiration_date]).to eql '2059-07-14'
      end

      it { should respond_with 200 }
    end
  end

  describe 'POST #quick_search' do
    context 'when successful' do
      let(:user) { FactoryBot.create(:user) }
      before { create_items_for_quick_search('SN', 10) }

      before(:each) do
        api_authorization_header user.auth_token

        post :quick_search, params: { keyword: 'sn' }, format: :json
      end

      it 'returns InventoryItems that have occurrence of "SN" in serial number' do
        items_response = json_response[:inventory_items]
        expect(items_response.count).to eql 10
      end

      it { should respond_with 200 }
    end

    context 'when not successful' do
      let(:user) { FactoryBot.create(:user) }
      before { create_items_for_quick_search('SN', 10) }

      before(:each) do
        api_authorization_header user.auth_token

        post :quick_search, format: :json
      end

      it 'raises error when keyword not present' do
        error_response = json_response[:errors]
        expect(error_response).to eql 'La palabra clave no puede estar vacía.'
      end

      it { should respond_with 422 }
    end
  end

  describe 'POST #re_entry' do
    let(:user) { FactoryBot.create(:user) }
    let(:inventory_item) { FactoryBot.create(:inventory_item, quantity: 100) }
    let(:entry_date) { Date.today }
    let(:delivery_company) { FactoryBot.create(:supplier) }
    let(:state) { InventoryItem::GOOD }

    context 'when successful' do
      before(:each) do
        api_authorization_header user.auth_token

        post :re_entry,
             params: {
               id: inventory_item.id,
               entry_date: entry_date,
               delivery_company: delivery_company,
               delivery_company_contact: 'Juan Repartidor',
               state: state,
               additional_comments: 'Comentarios adicionales',
               quantity: 100
             },
             format: :json
      end

      it 'adds quantity to InventoryItem' do
        inventory_item.reload

        expect(inventory_item.quantity).to eq 200
        expect(json_response).to have_key(:success)
      end

      it 'logs an InventoryTransaction with a CheckIn folio' do
        last_transaction = CheckInTransaction.last

        expect(last_transaction.quantity).to eq 100
        expect(last_transaction.folio).not_to eq '-'
        expect(last_transaction.folio).to include 'FE-'
      end

      it { should respond_with 201 }
    end

    context 'when not successful' do
      before(:each) do
        api_authorization_header user.auth_token

        post :re_entry,
             params: {
               id: inventory_item.id,
               entry_date: entry_date,
               delivery_company: delivery_company,
               delivery_company_contact: 'Juan Repartidor',
               state: state,
               additional_comments: 'Comentarios adicionales',
               quantity: -100
             },
             format: :json
      end

      it 'should return errors' do
        expect(json_response).to have_key(:errors)
      end

      it { should respond_with 422 }
    end
  end
end
