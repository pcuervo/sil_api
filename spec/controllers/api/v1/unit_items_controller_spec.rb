require 'spec_helper'

describe Api::V1::UnitItemsController do
  describe "GET #show" do
    before(:each) do
      @unit_item = FactoryGirl.create :unit_item
      get :show, id: @unit_item.id
    end

    it "returns the information about a unit_item in JSON format" do
      unit_item_response = json_response[:unit_item]
      expect(unit_item_response[:serial_number]).to eql @unit_item.serial_number
      expect(unit_item_response[:brand]).to eql @unit_item.brand
      expect(unit_item_response[:model]).to eql @unit_item.model
    end

    it "should have all the attributes of an inventory_item" do
      unit_item_response = json_response[:unit_item]
      expect(unit_item_response[:name]).to eql @unit_item.name
      expect(unit_item_response[:description]).to eql @unit_item.description
      expect(unit_item_response[:image_url]).to eql @unit_item.image_url
      expect(unit_item_response[:status]).to eql @unit_item.status
    end

    it { should respond_with 200 }
  end

  describe "GET #index" do
    before(:each) do
      5.times{ FactoryGirl.create :unit_item }
      get :index
    end

    it "returns 5 unit items from the database" do
      unit_items_response = json_response
      expect(unit_items_response[:unit_items].size).to eq(5)
    end

    it { should respond_with 200 }
  end

  describe "POST #create" do
    context "when is succesfully created" do
      before(:each) do
        user = FactoryGirl.create :user
        project = FactoryGirl.create :project

        @unit_item_attributes = FactoryGirl.attributes_for :unit_item
        @unit_item_attributes[:project_id] = project.id

        api_authorization_header user.auth_token
        post :create, { user_id: user.id, unit_item: @unit_item_attributes, :entry_date => Time.now, :storage_type => 'Permanente', :delivery_company => 'DHL' }
      end

      it "renders the json representation for the inventory item just created" do
        unit_item_response = json_response[:unit_item]
        expect(unit_item_response[:name]).to eql @unit_item_attributes[:name]
      end

      it "should record the transaction in database" do
        unit_item_response = json_response[:unit_item]
        inv_item = InventoryItem.find_by_actable_id(unit_item_response[:id])
        inv_transaction = InventoryTransaction.find_by_inventory_item_id(inv_item.id)
        expect(inv_transaction.to_json.size).to be >= 1
      end

      it { should respond_with 201 }
    end

    context "when is not created" do
      before(:each) do
        user = FactoryGirl.create :user
        @invalid_unit_item_attributes = { user_id: user.id }

        api_authorization_header user.auth_token
        post :create, { user_id: user.id, unit_item: @invalid_unit_item_attributes }
      end

      it "renders an errors json" do
        unit_item_response = json_response
        expect(unit_item_response).to have_key(:errors)
      end

      it "renders the json errors on why the inventory item could not be created" do
        unit_item_response = json_response

        expect(unit_item_response[:errors][:name]).to include "can't be blank"
      end

      it { should respond_with 422 }
    end
  end

  describe "POST #withdraw" do
    context "when unit item is succesfully withdrawn" do
      before(:each) do
        user = FactoryGirl.create :user
        @unit_item = FactoryGirl.create :unit_item

        api_authorization_header user.auth_token
        post :withdraw, { id: @unit_item.id, quantity: 120, :exit_date => Time.now, :storage_type => 'Permanente', :pickup_company => 'DHL' }
      end

      it "returns a success message about the withdrawn item" do
        success_msg = json_response
        expect(success_msg).to have_key(:success)
      end

      it { should respond_with 201 }
    end

    context "when unit item could not be withdrawn because item doesn't exist" do
      before(:each) do
        invalid_id = -1
        post :withdraw, { id: invalid_id }
      end

      it "renders an errors json" do
        unit_item_response = json_response
        expect(unit_item_response).to have_key(:errors)
      end

      it "renders the json errors when the item couldn't be found" do
        unit_item_response = json_response
        expect(unit_item_response[:errors]).to include "No se encontró el artículo."
      end

      it { should respond_with 422 }
    end

    context "when unit item could not be withdrawn because it's out of stock, pending withdrawal of pending entry" do
      before(:each) do
        @unit_item = FactoryGirl.create :unit_item
      end

      it "renders the json errors when the item is already out of stock" do
        @unit_item.status = InventoryItem::OUT_OF_STOCK
        @unit_item.save
        post :withdraw, { id: @unit_item }
        unit_item_response = json_response
        expect(unit_item_response).to have_key(:errors)
        expect(unit_item_response[:errors]).to include 'No se pudo completar la salida por que el artículo "' + @unit_item.name + '" no se encuentra en existencia.'
      end

      it "renders the json errors when the item is pending entry" do
        @unit_item.status = InventoryItem::PENDING_ENTRY
        @unit_item.save
        post :withdraw, { id: @unit_item }
        unit_item_response = json_response
        expect(unit_item_response).to have_key(:errors)
        expect(unit_item_response[:errors]).to include 'No se pudo completar la salida por que el artículo "' + @unit_item.name + '" no ha ingresado al almacén.'
      end

      it "renders the json errors when the item is pending withdrawal" do
        @unit_item.status = InventoryItem::PENDING_WITHDRAWAL
        @unit_item.save
        post :withdraw, { id: @unit_item }
        unit_item_response = json_response
        expect(unit_item_response[:errors]).to include 'No se pudo completar la salida por que el artículo "' + @unit_item.name + '" tiene una salida programada.'
      end

    end


  end
end
