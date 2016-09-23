require 'spec_helper'

RSpec.describe DeliveryRequest, type: :model do
  #before { @delivery_request = FactoryGirl.build(:delivery_request) }

  describe ".authorize" do
    before(:each) do
      @delivery_request_item = FactoryGirl.create :delivery_request_item
      @delivery_request = @delivery_request_item.delivery_request
      @bulk_item = FactoryGirl.create :bulk_item
      @inventory_item = FactoryGirl.create :inventory_item
      @inventory_item.actable_type = 'BulkItem'
      @inventory_item.actable_id = @bulk_item.id
      @inventory_item.save
      @delivery_request_item.inventory_item = @inventory_item
      @delivery_request_item.save
      @delivery_request.delivery_request_items << @delivery_request_item
      @delivery_request.save

      supplier = FactoryGirl.create :supplier
      supplier.name = 'Litobel'
      supplier.save
    end

    it "returns true when the delivery request has been authorized and quantities were not modified" do
      supplier = FactoryGirl.create :supplier
      delivery_guy = FactoryGirl.create :user
      delivery_guy.role = User::DELIVERY
      delivery_guy.save
      authorized = @delivery_request.authorize( delivery_guy.id, supplier.id, 'adicionales' )
      expect( DeliveryRequest.all.count ).to eql 0
      expect( DeliveryRequestItem.all.count ).to eql 0
      expect( Delivery.all.count ).to eql 1
    end

  end
end
