require 'spec_helper'

describe Api::V1::InventoryItemsController do
  describe "GET #show" do
    before(:each) do
      @inventory_item = FactoryGirl.create :inventory_item
      @location = FactoryGirl.create :warehouse_location
      item_location = ItemLocation.new
      item_location.inventory_item = @inventory_item
      item_location.warehouse_location = @location
      item_location.units = 10
      item_location.quantity = 1
      item_location.save
      get :show, id: @inventory_item.id
    end

    it "returns the information about an inventory item on a hash" do
      inventory_item_response = json_response[:inventory_item]
      expect(inventory_item_response[:name]).to eql @inventory_item.name
      expect(inventory_item_response).to have_key(:locations)
    end

    it { should respond_with 200 }
  end

  describe "GET #index" do
    before(:each) do
      5.times{ FactoryGirl.create :inventory_item }
      get :index
    end

    it "returns 5 inventory items from the database" do
      inventory_items_response = json_response[:inventory_items]

      expect(inventory_items_response.size).to eq(5)
    end

    it { should respond_with 200 }
  end

  describe "POST #create" do
    context "when is succesfully created" do
      before(:each) do
        user = FactoryGirl.create :user
        project = FactoryGirl.create :project
        client = FactoryGirl.create :client

        @inventory_item_attributes = FactoryGirl.attributes_for :inventory_item
        @inventory_item_attributes[:project_id] = project.id
        @inventory_item_attributes[:client_id] = client.id

        api_authorization_header user.auth_token
        post :create, { user_id: user.id, inventory_item: @inventory_item_attributes, item_img_ext: 'jpg' }
      end

      it "renders the json representation for the inventory item just created" do
        inventory_item_response = json_response[:inventory_item]
        expect(inventory_item_response[:name]).to eql @inventory_item_attributes[:name]
      end

      it { should respond_with 201 }
    end

    context "when is not created" do
      before(:each) do
        user = FactoryGirl.create :user
        @invalid_inventory_item_attributes = { user_id: user.id }

        api_authorization_header user.auth_token
        post :create, { user_id: user.id, inventory_item: @invalid_inventory_item_attributes, item_img_ext: 'jpg' }
      end

      it "renders an errors json" do
        inventory_item_response = json_response
        expect(inventory_item_response).to have_key(:errors)
      end

      it "renders the json errors on why the inventory item could not be created" do
        inventory_item_response = json_response

        expect(inventory_item_response[:errors][:name]).to include "can't be blank"
      end

      it { should respond_with 422 }
    end
  end

  describe "GET #pending_entries" do
    before(:each) do
      # TODO
    end
  end

  describe "GET #authorize_entry" do
    before(:each) do
      # TODO
    end
  end

  describe "GET #total_number_items" do
    before(:each) do
      5.times{ FactoryGirl.create :inventory_item }
      get :total_number_items
    end

    it "returns the information about an inventory item on a hash" do
      inventory_item_response = json_response[:total_number_items]
      expect(inventory_item_response).to eql 5
    end

    it { should respond_with 200 }
  end

  describe "GET #inventory_value" do
    before(:each) do
      @value = 0
      5.times do
        item = FactoryGirl.create :inventory_item 
        @value += item.value
      end
      get :inventory_value
    end

    it "returns the information about an inventory item on a hash" do
      inventory_item_response = json_response[:inventory_value]
      expect( inventory_item_response.to_f ).to eql @value.to_f
    end

    it { should respond_with 200 }
  end

  describe "POST #multiple_withdrawal" do
    context "when multiple UnitItems with location are succesfully withdrawn" do
      before(:each) do
        user = FactoryGirl.create :user
        
        inventory_item_ids = []
        3.times do 
          inventory_item = FactoryGirl.create :inventory_item
          unit_item = FactoryGirl.create :unit_item
          unit_item.actable_id = inventory_item.id
          item_location = FactoryGirl.create :item_location
          unit_item.item_locations << item_location
          warehouse_location.item_locations << item_location
          inventory_item_ids.push( unit_item.id )
        end 

        puts inventory_item_ids.to_yaml

        api_authorization_header user.auth_token
        post :multiple_withdrawal, { inventory_item_ids: inventory_item_ids }
      end

      it "returns the number of withdrawn items along with success message" do
        inventory_item_response = json_response
        expect( inventory_item_response[:items_withdrawn] ).to eql 3
        expect( inventory_item_response ).to have_key(:success)
      end

      it { should respond_with 201 }
    end

  end

end
