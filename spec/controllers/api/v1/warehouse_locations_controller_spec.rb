require 'spec_helper'

RSpec.describe Api::V1::WarehouseLocationsController, type: :controller do
  describe "GET #show" do 
    before(:each) do
      @warehouse_location = FactoryBot.create :warehouse_location
      get :show, params: { id: @warehouse_location.id }
    end

    it "returns the information about a warehouse_location in JSON format" do
      warehouse_location_response = json_response[:warehouse_location]
      expect(warehouse_location_response[:name]).to eql @warehouse_location.name
      expect(warehouse_location_response[:status]).to eql @warehouse_location.status
    end

    it { should respond_with 200 }
  end

  describe "GET #index" do 
    before(:each) do
      3.times { FactoryBot.create :warehouse_location }
      get :index
    end

    it "returns 5 items from the database" do
      bulk_items_response = json_response
      expect(bulk_items_response[:warehouse_locations].size).to eq(3)
    end

    it { should respond_with 200 }
  end

  describe "POST #locate_item" do 
    before(:each) do
      user = FactoryBot.create :user
      inventory_item = FactoryBot.create :inventory_item

      @warehouse_location = FactoryBot.create :warehouse_location

      api_authorization_header user.auth_token
      post :locate_item, params: { inventory_item_id: inventory_item.id, warehouse_location_id: @warehouse_location.id, quantity: 1 }
    end

    context "when item is successfully located" do
      it "returns a JSON of the new ItemLocation" do
        item_location_response = json_response[:item_location]
        expect(item_location_response[:quantity]).to eq(1)
      end

      it { should respond_with 201 }
    end
  end

  describe "POST #relocate_item" do 
    let(:inventory_item) { FactoryBot.create(:inventory_item) }
    let(:source_location){ FactoryBot.create(:warehouse_location) }
    let(:destination_location){ FactoryBot.create(:warehouse_location) }

    context "when full relocation" do
      context 'when successful' do
        before(:each) do
          source_location.locate(inventory_item, inventory_item.quantity)
    
          user = FactoryBot.create :user
          api_authorization_header user.auth_token
          post :relocate_item, 
                params: 
                  { 
                    inventory_item_id: inventory_item.id, 
                    old_location_id: source_location.id,
                    new_location_id: destination_location.id, 
                    quantity: inventory_item.quantity
                  }
        end

        it "returns a JSON of the new ItemLocation" do
          item_location_response = json_response[:item_location]
          expect(item_location_response[:quantity]).to eq( inventory_item.quantity )
        end

        it { should respond_with 201 }
      end

      context 'when not successful' do
        before(:each) do
          source_location.locate(inventory_item, inventory_item.quantity)
          invalid_quantity = inventory_item.quantity+10
    
          user = FactoryBot.create :user
          api_authorization_header user.auth_token
          post :relocate_item, 
                params: 
                  { 
                    inventory_item_id: inventory_item.id, 
                    old_location_id: source_location.id,
                    new_location_id: destination_location.id, 
                    quantity: invalid_quantity
                  }
        end

        it "returns an error" do
          error = json_response[:errors]
          expect(error).to eq( 'La cantidad a reubicar es mayor a la cantidad disponbile en la ubicación' )
        end

        it { should respond_with 422 }
      end
    end

    context "when partial relocation" do
      before(:each) do
        source_location.locate(inventory_item, inventory_item.quantity)
  
        user = FactoryBot.create :user
        api_authorization_header user.auth_token
        post :relocate_item, 
              params: 
                { 
                  inventory_item_id: inventory_item.id, 
                  old_location_id: source_location.id,
                  new_location_id: destination_location.id, 
                  quantity: inventory_item.quantity-10
                }
      end

      it "returns a JSON of the new ItemLocation" do
        old_item_location = ItemLocation.find_by(
          inventory_item_id: inventory_item.id,
          warehouse_location_id: source_location.id
        )
        item_location_response = json_response[:item_location]
        expect(item_location_response[:quantity]).to eq( inventory_item.quantity-10 )
        expect(old_item_location.quantity).to eq( 10 )
      end

      it { should respond_with 201 }
    end
  end

  describe "PUT/PATCH #update" do

    context "when is successfully updated" do
      before(:each) do
        user = FactoryBot.create :user
        api_authorization_header user.auth_token
        @warehouse_location = FactoryBot.create :warehouse_location
        post :update, params: { id: @warehouse_location.id, name: "NewNameBro", quantity: 50 }, format: :json
      end

      it "renders the json representation for the updated WarehouseLocation" do
        warehouse_location_response = json_response[:warehouse_location]
        expect(warehouse_location_response[:name]).to eql "NewNameBro"
      end

      it { should respond_with 200 }
    end

  end

end
