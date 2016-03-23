require 'spec_helper'

describe BulkItem, type: :model do
  let(:bulk_item) { FactoryGirl.create :bulk_item }
  subject { bulk_item }

  it { should respond_to(:name) }
  it { should respond_to(:description) }
  it { should respond_to(:image_url) }
  it { should respond_to(:status) }
  it { should respond_to(:item_type) }
  it { should respond_to(:barcode) }
  it { should respond_to(:quantity) }
  it { should respond_to(:state) }
  it { should respond_to(:value) }
  
  describe ".withdraw" do
    before(:each) do
      @bulk_item = FactoryGirl.create :bulk_item
    end

    context "withdraws a BulkItem with location successfuly" do
      before(:each) do
        @warehouse_location = FactoryGirl.create :warehouse_location
        @item_location = FactoryGirl.create :item_location
        @item_location.quantity = @bulk_item.quantity
        @item_location.save
        @bulk_item.item_locations << @item_location
        @warehouse_location.item_locations << @item_location
        @supplier = FactoryGirl.create :supplier
        @withdraw = @bulk_item.withdraw( Time.now, Time.now + 10.days, @supplier.id, 'John Doe', 'This is just a test' )
      end

      it "returns true if withdrawal was sucessful" do
        expect( @withdraw ).to eq true
      end

      it "changes BulkItem status to Out of Stock" do
        expect( @bulk_item.status ).to eq InventoryItem::OUT_OF_STOCK
      end

      it "records the WarehouseTransaction" do
        last_transaction = WarehouseTransaction.last
        expect( last_transaction.quantity ).to eq @item_location.quantity
      end

      it "deletes ItemLocation associated with BulkItem" do
        item_location = ItemLocation.find_by_id( @item_location.id )
        expect( item_location.present? ).to eq false
      end
    end

    # context "cannot withdraw a BulkItem with location successfuly" do
    #   before(:each) do
    #     @warehouse_location = FactoryGirl.create :warehouse_location
    #     @item_location = FactoryGirl.create :item_location
    #     @bulk_item.item_locations << @item_location
    #     @warehouse_location.item_locations << @item_location
    #     @supplier = FactoryGirl.create :supplier
    #   end

    #   it "returns 2 if withdrawal was not sucessful because BulkItem is already out of stock" do
    #     @bulk_item.status = InventoryItem::OUT_OF_STOCK
    #     @withdraw = @bulk_item.withdraw( Time.now, Time.now + 10.days, @supplier.id, 'John Doe', 'This is just a test' )
    #     expect( @withdraw ).to eq InventoryItem::OUT_OF_STOCK
    #   end

    #   it "returns 2 if withdrawal was not sucessful because BulkItem has a pending entry" do
    #     @bulk_item.status = InventoryItem::PENDING_ENTRY
    #     @withdraw = @bulk_item.withdraw( Time.now, Time.now + 10.days, @supplier.id, 'John Doe', 'This is just a test' )
    #     expect( @withdraw ).to eq InventoryItem::PENDING_ENTRY
    #   end

    #   # it "deletes ItemLocation associated with BulkItem" do
    #   #   item_location = ItemLocation.find_by_id( @item_location.id )
    #   #   expect( item_location.present? ).to eq false
    #   # end
    # end

  end

end
