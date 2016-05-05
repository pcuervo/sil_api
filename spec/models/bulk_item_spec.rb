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

    context "withdraws whole quantity of BulkItem with location successfuly" do
      before(:each) do
        @warehouse_location = FactoryGirl.create :warehouse_location
        @item_location = FactoryGirl.create :item_location
        @item_location.quantity = @bulk_item.quantity
        @item_location.save
        @bulk_item.item_locations << @item_location
        @warehouse_location.item_locations << @item_location
        @supplier = FactoryGirl.create :supplier
        @withdraw = @bulk_item.withdraw( Time.now, Time.now + 10.days, @supplier.id, 'John Doe', 'This is just a test', '' )
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
        expect( @warehouse_location.item_locations.count ).to eq 0
      end
    end

    context "withdraws partial quantity of BulkItem from one location successfuly" do
      before(:each) do
        @warehouse_location = FactoryGirl.create :warehouse_location
        @item_location = FactoryGirl.create :item_location
        @item_location.quantity = @bulk_item.quantity
        @item_location.save
        @bulk_item.item_locations << @item_location
        @warehouse_location.item_locations << @item_location
        @supplier = FactoryGirl.create :supplier
        @withdraw = @bulk_item.withdraw( Time.now, Time.now + 10.days, @supplier.id, 'John Doe', 'This is just a test', 1 )
      end

      it "returns true if withdrawal was sucessful" do
        expect( @withdraw ).to eq true
      end

      it "changes BulkItem status to Out of Stock" do
        expect( @bulk_item.status ).to eq InventoryItem::IN_STOCK
      end

      it "records the WarehouseTransaction" do
        last_transaction = WarehouseTransaction.last
        expect( last_transaction.quantity ).to eq 1
      end

    end

    context "withdraws partial quantity of BulkItem from multiple locations successfuly" do
      before(:each) do
        @warehouse_location = FactoryGirl.create :warehouse_location
        @item_location = FactoryGirl.create :item_location
        @item_location.quantity = @bulk_item.quantity
        @item_location.save

        @warehouse_location2 = FactoryGirl.create :warehouse_location
        @item_location2 = FactoryGirl.create :item_location
        @item_location2.quantity = @bulk_item.quantity
        @item_location2.save

        @bulk_item.quantity = @bulk_item.quantity.to_i * 2
        @bulk_item.save

        @bulk_item.item_locations << @item_location
        @bulk_item.item_locations << @item_location2
        @warehouse_location.item_locations << @item_location
        @warehouse_location2.item_locations << @item_location2
        @supplier = FactoryGirl.create :supplier
        @withdraw = @bulk_item.withdraw( Time.now, Time.now + 10.days, @supplier.id, 'John Doe', 'This is just a test', 101 )
      end

      it "returns true if withdrawal was sucessful" do
        expect( @withdraw ).to eq true
      end

      it "changes BulkItem status to Out of Stock" do
        expect( @bulk_item.status ).to eq InventoryItem::IN_STOCK
      end

      it "records the WarehouseTransaction" do
        last_transaction = WarehouseTransaction.last
        expect( last_transaction.quantity ).to eq 1
        expect( WarehouseTransaction.all.count ).to eq 2
      end

    end

  end

end
