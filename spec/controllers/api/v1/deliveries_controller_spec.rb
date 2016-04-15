require 'spec_helper'

RSpec.describe Api::V1::DeliveriesController, type: :controller do
  describe "GET #show" do
    before(:each) do
      @delivery = FactoryGirl.create :delivery
      get :show, id: @delivery.id
    end

    it "returns the information about an inventory item on a hash" do
      delivery_response = json_response[:delivery]
      expect(delivery_response[:address]).to eql @delivery.address
      expect(delivery_response).to have_key(:delivery_items)
    end

    it { should respond_with 200 }
  end

  describe "GET #index" do
    before(:each) do
      5.times { FactoryGirl.create :delivery }
      get :index
    end

    it "returns 5 records from the database" do
      delivery_response = json_response[:deliveries]
      expect(delivery_response.size).to eq(5)
    end

    it { should respond_with 200 }
  end

  describe "POST #create" do
    context "when is succesfully created" do
      before(:each) do
        @user = FactoryGirl.create :user
        @delivery_user = FactoryGirl.create :user
        @delivery_user.save
        @delivery_user.role = User::DELIVERY

        @items = []
        2.times do |t|
          item_data = {}
          item = FactoryGirl.create :inventory_item 
          item_data[:item_id] = item.id 
          item_data[:quantity] = 1
          @items.push( item_data )
        end
        
        @delivery_attributes = FactoryGirl.attributes_for :delivery
        @delivery_attributes[:delivery_user_id] = @delivery_user.id

        api_authorization_header @user.auth_token
        post :create, { user_id: @user.id, delivery: @delivery_attributes, inventory_items: @items, item_img_ext: 'jpg' }
      end

      it "renders the json representation for the inventory item just created" do
        delivery_response = json_response[:delivery]
        expect(delivery_response[:address]).to eql @delivery_attributes[:address]
        expect(delivery_response[:delivery_user_id]).to eql @delivery_user.id
      end

      it "has at least 1 InventoryItem" do
        delivery = Delivery.last
        expect( delivery.delivery_items.count ).to eq 2
      end

      it { should respond_with 201 }
    end

    # context "when is not created" do
    #   before(:each) do
    #     user = FactoryGirl.create :user
    #     @invalid_inventory_item_attributes = { user_id: user.id }

    #     api_authorization_header user.auth_token
    #     post :create, { user_id: user.id, inventory_item: @invalid_inventory_item_attributes, item_img_ext: 'jpg' }
    #   end

    #   it "renders an errors json" do
    #     inventory_item_response = json_response
    #     expect(inventory_item_response).to have_key(:errors)
    #   end

    #   it "renders the json errors on why the inventory item could not be created" do
    #     inventory_item_response = json_response

    #     expect(inventory_item_response[:errors][:name]).to include "can't be blank"
    #   end

    #   it { should respond_with 422 }
    # end
  end

end
