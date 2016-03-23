require 'spec_helper'

describe UnitItem do

  let(:unit_item) { FactoryGirl.create :unit_item }
  subject { unit_item }

  it { should respond_to(:name) }
  it { should respond_to(:description) }
  it { should respond_to(:image_url) }
  it { should respond_to(:status) }
  it { should respond_to(:serial_number) }
  it { should respond_to(:brand) }
  it { should respond_to(:model) }
  it { should respond_to(:item_type) }
  it { should respond_to(:barcode) }
  it { should respond_to(:state) }
  it { should respond_to(:value) }

  it { should validate_uniqueness_of :serial_number }
  it { should validate_uniqueness_of :barcode }

  describe ".withdraw" do
    before(:each) do
      @unit_item = FactoryGirl.create :unit_item
    end

    context "withdraws a UnitItem with location successfuly" do
      before(:each) do
        @warehouse_location = FactoryGirl.create :warehouse_location
        @item_location = FactoryGirl.create :item_location
        @unit_item.item_locations << @item_location
        @warehouse_location.item_locations << @item_location
        @supplier = FactoryGirl.create :supplier
        @withdraw = @unit_item.withdraw( Time.now, Time.now + 10.days, @supplier.id, 'John Doe', 'This is just a test' )
      end

      it "returns true if withdrawal was sucessful" do
        expect( @withdraw ).to eq true
      end

      it "changes UniItem status to Out of Stock" do
        expect( @unit_item.status ).to eq InventoryItem::OUT_OF_STOCK
      end

      it "deletes ItemLocation associated with UnitItem" do
        item_location = ItemLocation.find_by_id( @item_location.id )
        expect( item_location.present? ).to eq false
      end
    end

    context "cannot withdraw a UnitItem with location successfuly" do
      before(:each) do
        @warehouse_location = FactoryGirl.create :warehouse_location
        @item_location = FactoryGirl.create :item_location
        @unit_item.item_locations << @item_location
        @warehouse_location.item_locations << @item_location
        @supplier = FactoryGirl.create :supplier
      end

      it "returns 2 if withdrawal was not sucessful because UnitItem is already out of stock" do
        @unit_item.status = InventoryItem::OUT_OF_STOCK
        @withdraw = @unit_item.withdraw( Time.now, Time.now + 10.days, @supplier.id, 'John Doe', 'This is just a test' )
        expect( @withdraw ).to eq InventoryItem::OUT_OF_STOCK
      end

      it "returns 2 if withdrawal was not sucessful because UnitItem has a pending entry" do
        @unit_item.status = InventoryItem::PENDING_ENTRY
        @withdraw = @unit_item.withdraw( Time.now, Time.now + 10.days, @supplier.id, 'John Doe', 'This is just a test' )
        expect( @withdraw ).to eq InventoryItem::PENDING_ENTRY
      end

      # it "deletes ItemLocation associated with UnitItem" do
      #   item_location = ItemLocation.find_by_id( @item_location.id )
      #   expect( item_location.present? ).to eq false
      # end
    end

  end

end
