require 'spec_helper'

describe Api::V1::BulkItemsController, type: :controller do
  describe "GET #show" do
    before(:each) do
      @bulk_item = FactoryGirl.create :bulk_item
      get :show, id: @bulk_item.id
    end

    it "returns the information about a bulk_item in JSON format" do
      bulk_item_response = json_response[:bulk_item]
      expect(bulk_item_response[:quantity]).to eql @bulk_item.quantity
    end

    it "should have all the attributes of an inventory_item" do
      bulk_item_response = json_response[:bulk_item]
      expect(bulk_item_response[:name]).to eql @bulk_item.name
      expect(bulk_item_response[:description]).to eql @bulk_item.description
      expect(bulk_item_response[:image_url]).to eql @bulk_item.image_url
      expect(bulk_item_response[:status]).to eql @bulk_item.status
      expect(bulk_item_response[:barcode]).to eql @bulk_item.barcode
    end

    it { should respond_with 200 }
  end

  describe "GET #index" do
    before(:each) do
      5.times{ FactoryGirl.create :bulk_item }
      get :index
    end

    it "returns 5 unit items from the database" do
      bulk_items_response = json_response
      expect(bulk_items_response[:bulk_items].size).to eq(5)
    end

    it { should respond_with 200 }
  end

  describe "POST #create" do
    context "when is succesfully created" do
      before(:each) do
        user = FactoryGirl.create :user
        project = FactoryGirl.create :project

        @bulk_item_attributes = FactoryGirl.attributes_for :bulk_item
        @bulk_item_attributes[:project_id] = project.id

        api_authorization_header user.auth_token
        post :create, { user_id: user.id, bulk_item: @bulk_item_attributes, :entry_date => Time.now, :storage_type => 'Permanente', :delivery_company => 'DHL' }
      end

      it "renders the json representation for the inventory item just created" do
        bulk_item_response = json_response[:inventory_item]
        expect(bulk_item_response[:name]).to eql @bulk_item_attributes[:name]
        expect(bulk_item_response[:state]).to eql @bulk_item_attributes[:state]
        expect(bulk_item_response[:value].to_i).to eql @bulk_item_attributes[:value]
      end

      it "should record the transaction in database" do
        bulk_item_response = json_response[:inventory_item]
        inv_item = InventoryItem.find(bulk_item_response[:id])
        inv_transaction = InventoryTransaction.find_by_inventory_item_id(inv_item.id)
        expect(inv_transaction.to_json.size).to be >= 1
      end

      it { should respond_with 201 }
    end

    context "when is not created" do
      before(:each) do
        user = FactoryGirl.create :user
        @invalid_bulk_item_attributes = { user_id: user.id }

        api_authorization_header user.auth_token
        post :create, { user_id: user.id, bulk_item: @invalid_bulk_item_attributes }
      end

      it "renders an errors json" do
        bulk_item_response = json_response
        expect(bulk_item_response).to have_key(:errors)
      end

      it "renders the json errors on why the inventory item could not be created" do
        bulk_item_response = json_response

        expect(bulk_item_response[:errors][:name]).to include "can't be blank"
      end

      it { should respond_with 422 }

    end
  end

  describe "POST #update" do
    context "when bulk_item is successfully updated" do
      before(:each) do
        @user = FactoryGirl.create :user
        @bulk_item = FactoryGirl.create :bulk_item
        api_authorization_header @user.auth_token
        post :update, { id: @bulk_item.id,
                          bulk_item: { name: 'My new name', state: 2 } }, format: :json
      end

      it "renders the json representation for the updated bulk_item" do
        bulk_item_response = json_response[:bulk_item]
        expect(bulk_item_response[:state]).to eql 2
        expect(bulk_item_response[:name]).to eql 'My new name'
      end

      it { should respond_with 200 }
    end
  end

  describe "POST #withdraw" do
    context "when bulk item is succesfully withdrawn" do
      before(:each) do
        user = FactoryGirl.create :user
        @bulk_item = FactoryGirl.create :bulk_item
        @bulk_item.quantity = 120
        @bulk_item.save

        api_authorization_header user.auth_token
        post :withdraw, { id: @bulk_item.id, quantity: 120, :exit_date => Time.now, :storage_type => 'Permanente', :pickup_company => 'DHL' }
      end

      it "returns a success message about the withdrawn item" do
        success_msg = json_response
        expect(success_msg).to have_key(:success)
      end

      it "returns the quantity left" do
        bulk_item_response = json_response
        expect(bulk_item_response[:quantity].to_i).to eql 0
      end

      it { should respond_with 201 }
    end

    context "when bulk item is succesfully withdrawn from chosen locations" do
      before(:each) do
        user = FactoryGirl.create :user
        @bulk_item = FactoryGirl.create :bulk_item
        @bulk_item.quantity = 120
        @bulk_item.save
        item_location_1 = FactoryGirl.create :item_location
        item_location_2 = FactoryGirl.create :item_location

        @bulk_item.item_locations << item_location_1 
        item_location_1.quantity = 40
        item_location_1.save
        @bulk_item.item_locations << item_location_2 
        item_location_2.quantity = 40
        item_location_2.save

        location_info = []
        location_info[0] = { 'location_id' => item_location_1.warehouse_location.id, 'quantity' => 40, 'units' => 5 }
        location_info[1] = { 'location_id' => item_location_2.warehouse_location.id, 'quantity' => 40, 'units' => 5 }

        api_authorization_header user.auth_token
        post :withdraw, { id: @bulk_item.id, quantity: 80, :exit_date => Time.now, :storage_type => 'Permanente', :pickup_company => 'DHL', :locations => location_info }
      end

      it "returns a success message about the withdrawn item" do
        success_msg = json_response
        expect(success_msg).to have_key(:success)
      end

      it "returns the quantity left" do
        last_warehouse_transaction = WarehouseTransaction.last
        bulk_item_response = json_response
        expect(bulk_item_response[:quantity].to_i).to eql last_warehouse_transaction.quantity
        expect(bulk_item_response[:quantity].to_i).to eql 40
      end

      it { should respond_with 201 }
    end

    context "when bulk item is succesfully withdrawn from mulitple locations automatically" do
      before(:each) do
        user = FactoryGirl.create :user
        @bulk_item = FactoryGirl.create :bulk_item
        @bulk_item.quantity = 120
        @bulk_item.save
        item_location_1 = FactoryGirl.create :item_location
        item_location_2 = FactoryGirl.create :item_location

        @bulk_item.item_locations << item_location_1 
        item_location_1.quantity = 40
        item_location_1.save
        @bulk_item.item_locations << item_location_2 
        item_location_2.quantity = 40
        item_location_2.save


        api_authorization_header user.auth_token
        post :withdraw, { id: @bulk_item.id, quantity: 80, :exit_date => Time.now, :storage_type => 'Permanente', :pickup_company => 'DHL' }
      end

      it "returns a success message about the withdrawn item" do
        success_msg = json_response
        expect(success_msg).to have_key(:success)
      end

      it "returns the quantity left" do
        last_warehouse_transaction = WarehouseTransaction.last
        bulk_item_response = json_response
        expect(bulk_item_response[:quantity].to_i).to eql last_warehouse_transaction.quantity
        expect(bulk_item_response[:quantity].to_i).to eql 40
      end

      it { should respond_with 201 }
    end

    context "when bundle item could not be withdrawn because item doesn't exist" do
      before(:each) do
        invalid_id = -1
        post :withdraw, { id: invalid_id }
      end

      it "renders an errors json" do
        bulk_item_response = json_response
        expect(bulk_item_response).to have_key(:errors)
      end

      it "renders the json errors when the item couldn't be found" do
        bulk_item_response = json_response
        expect(bulk_item_response[:errors]).to include "No se encontró el artículo."
      end

      it { should respond_with 422 }
    end

    context "when bundle item could not be withdrawn because the quantity drops below zero" do
      before(:each) do
        @bulk_item = FactoryGirl.create :bulk_item
        @bulk_item.quantity = 120
        @bulk_item.save
        post :withdraw, { id: @bulk_item.id, quantity: 121 }
      end

      it "renders an errors json" do
        bulk_item_response = json_response
        expect(bulk_item_response).to have_key(:errors)
      end

      it "renders the json errors that required quantity is more than available quantity" do
        bulk_item_response = json_response
        expect(bulk_item_response[:errors]).to include "¡No puedes sacar mas existencias de las que hay disponibles!"
      end

      it { should respond_with 422 }
    end

    context "when bundle item could not be withdrawn because it's out of stock, pending withdrawal of pending entry" do
      before(:each) do
        @bulk_item = FactoryGirl.create :bulk_item
      end

      it "renders the json errors when the item is already out of stock" do
        @bulk_item.status = InventoryItem::OUT_OF_STOCK
        @bulk_item.save
        post :withdraw, { id: @bulk_item }
        bulk_item_response = json_response
        expect(bulk_item_response).to have_key(:errors)
        expect(bulk_item_response[:errors]).to include 'No se pudo completar la salida por que el artículo "' + @bulk_item.name + '" no se encuentra en existencia.'
      end

      it "renders the json errors when the item is pending entry" do
        @bulk_item.status = InventoryItem::PENDING_ENTRY
        @bulk_item.save
        post :withdraw, { id: @bulk_item }
        bulk_item_response = json_response
        expect(bulk_item_response).to have_key(:errors)
        expect(bulk_item_response[:errors]).to include 'No se pudo completar la salida por que el artículo "' + @bulk_item.name + '" no ha ingresado al almacén.'
      end

      it "renders the json errors when the item is pending withdrawal" do
        @bulk_item.status = InventoryItem::PENDING_WITHDRAWAL
        @bulk_item.save
        post :withdraw, { id: @bulk_item }
        bulk_item_response = json_response
        expect(bulk_item_response[:errors]).to include 'No se pudo completar la salida por que el artículo "' + @bulk_item.name + '" tiene una salida programada.'
      end

    end

  end

end
