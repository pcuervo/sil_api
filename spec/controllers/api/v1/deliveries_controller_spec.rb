require 'spec_helper'

RSpec.describe Api::V1::DeliveriesController, type: :controller do
  describe "GET #show" do
    let(:delivery) { create_delivery_with_user }
    before(:each) do
      get :show, params: { id: delivery.id }
    end

    it "returns the information about an inventory item on a hash" do
      delivery_response = json_response[:delivery]
      expect(delivery_response[:address]).to eql delivery.address
      expect(delivery_response).to have_key(:delivery_items)
    end

    it { should respond_with 200 }
  end

  describe "GET #index" do
    before(:each) do
      5.times { FactoryBot.create :delivery }
      @user = FactoryBot.create(:user, role: User::ADMIN)

      api_authorization_header @user.auth_token
      get :index
    end

    it "returns 5 records from the database" do
      delivery_response = json_response[:deliveries]
      expect(delivery_response.size).to eq(5)
    end

    it { should respond_with 200 }
  end

  describe "POST #create" do
    before{ create_litobel_supplier }

    context "when is succesfully created by User Admin or WarehouseAdmin" do
      before(:each) do
        @user = FactoryBot.create(:user, role: User::ADMIN)
        @delivery_user = FactoryBot.create(:user, role: User::DELIVERY)

        @items = []
        2.times do |t|
          item_data = {}
          item = FactoryBot.create :inventory_item 
          item_data[:item_id] = item.id 
          item_data[:quantity] = 1
          @items.push( item_data )
        end
        
        @delivery_attributes = FactoryBot.attributes_for :delivery
        @delivery_attributes[:delivery_user_id] = @delivery_user.id

        api_authorization_header @user.auth_token
        post :create, params: { 
          user_id: @user.id, 
          delivery: @delivery_attributes, 
          inventory_items: @items
        }
      end

      it "renders the json representation for the inventory item just created" do
        delivery_response = json_response[:delivery]
        expect(delivery_response[:address]).to eql @delivery_attributes[:address]
        expect(delivery_response[:delivery_user_id]).to eql @delivery_user.id
        expect(delivery_response[:company]).to eql @delivery_attributes[:company]
        expect(delivery_response[:addressee]).to eql @delivery_attributes[:addressee]
        expect(delivery_response[:addressee_phone]).to eql @delivery_attributes[:addressee_phone]
        expect(delivery_response[:status]).to eql @delivery_attributes[:status]
        expect(delivery_response[:folio]).to eql CheckOutTransaction.last.folio
        expect(delivery_response[:user][:email]).to eql @user.email
      end

      it "has at least 1 InventoryItem" do
        delivery = Delivery.last
        expect( delivery.delivery_items.count ).to eq 2
      end

      it 'should generate CheckOut folio' do
        last_transaction = CheckOutTransaction.last

        expect(last_transaction.folio).to eq 'FS-0000001'
      end

      it { should respond_with 201 }
    end

    context "when a Delivery request is succesfully created by User PM or AE" do
      before(:each) do
        @admin = FactoryBot.create :user
        @admin.role = 1
        @admin.save
        @warehouse_admin = FactoryBot.create :user
        @warehouse_admin.role = 1
        @warehouse_admin.save
        @user = FactoryBot.create :user
        @delivery_user = FactoryBot.create :user
        @delivery_user.save
        @delivery_user.role = User::DELIVERY

        @items = []
        2.times do |t|
          item_data = {}
          item = FactoryBot.create :inventory_item 
          item_data[:item_id] = item.id 
          item_data[:quantity] = 1
          @items.push( item_data )
        end
        
        @delivery_attributes = FactoryBot.attributes_for :delivery
        @delivery_attributes[:delivery_user_id] = @delivery_user.id

        api_authorization_header @user.auth_token
        post :create, :params => { 
          user_id: @user.id,
          delivery: @delivery_attributes,
          inventory_items: @items
        }
      end

      it "renders the json representation for the inventory item just created" do
        delivery_response = json_response[:delivery]
        expect(delivery_response[:status]).to eql Delivery::PENDING_APPROVAL
      end

      it "should send a Notification to Admin and WarehouseAdmin" do
        expect( @admin.notifications.count ).to eql 1
        expect( @warehouse_admin.notifications.count ).to eql 1
      end

      it { should respond_with 201 }
    end
  end

  describe "POST #update" do
    context "when delivery is successfully updated" do
      before(:each) do
        @user = FactoryBot.create :user
        @delivery = FactoryBot.create :delivery
        api_authorization_header @user.auth_token
        post :update, params: { id: @delivery.id,
                          delivery: { company: 'La Nueva', status: 2 } }, format: :json
      end

      it "renders the json representation for the updated delivery" do
        delivery_response = json_response[:delivery]
        expect( delivery_response[:company] ).to eql "La Nueva"
        expect( delivery_response[:status].to_i ).to eql 2
      end

      it { should respond_with 200 }
    end
  end

  describe "POST #by_keyword" do
    before(:each) do
      FactoryBot.create :supplier
      @delivery = FactoryBot.create :delivery
      @another_delivery = FactoryBot.create :delivery

      @items = []
      5.times do |t| 
        delivery_item = {}
        item = FactoryBot.create :inventory_item
        item.update(name: 'MiItem'+t.to_s)
        
        delivery_item[:item_id] = item.id
        delivery_item[:quantity] = 1
        @items.push(delivery_item)
      end
      
      @delivery.add_items( @items, 'El Chomper', 'No comments' )
      @other_items = [@items.first] 
      @another_delivery.add_items( @other_items, 'El Mamfred', 'With comments' )

      post :by_keyword, params: { keyword: 'MiItem' }, format: :json
    end

    it "returns all Deliveries with items that have an occurrence of the keyword, serial number or barcode" do
      delivery_response = json_response[:deliveries]
      expect( delivery_response.count).to eql 2
    end

    #it { should respond_with 200 }
  end
end
