require 'spec_helper'

describe BundleItem, type: :model do
  let(:bundle_item) { FactoryGirl.create :bundle_item }
  subject { bundle_item }

  it { should respond_to(:name) }
  it { should respond_to(:description) }
  it { should respond_to(:image_url) }
  it { should respond_to(:status) }
  it { should respond_to(:item_type) }
  it { should respond_to(:barcode) }
  it { should respond_to(:num_parts) }
  it { should respond_to(:is_complete) }

  it { should have_many(:bundle_item_parts) }

  it { should validate_numericality_of(:num_parts) }
  it { should_not allow_value(-1).for(:num_parts) }
  it { should allow_value(0).for(:num_parts) }

  describe ".update_num_parts" do
    before(:each) do
      @bundle_item = FactoryGirl.create :bundle_item
      @part1 = FactoryGirl.create :bundle_item_part
      @part2 = FactoryGirl.create :bundle_item_part
      @part3 = FactoryGirl.create :bundle_item_part
      @bundle_item.bundle_item_parts << @part1
      @bundle_item.bundle_item_parts << @part2
      @bundle_item.bundle_item_parts << @part3
    end

    it "updates the number of parts" do
      @bundle_item.update_num_parts
      expect(@bundle_item.num_parts).to eql 3
    end
  end

  describe ".add_new_parts" do
    before(:each) do
      @bundle_item = FactoryGirl.create :bundle_item
      @part1 = FactoryGirl.attributes_for :bundle_item_part
      @part2 = FactoryGirl.attributes_for :bundle_item_part
      @parts_arr = [ ActionController::Parameters.new( @part1 ), ActionController::Parameters.new( @part2 ) ]
    end

    it "returns the number of parts added" do
      @bundle_item.add_new_parts( @parts_arr )
      expect(@bundle_item.num_parts).to eql 2
    end
  end

  describe ".remove_parts" do
    before(:each) do
      @bundle_item = FactoryGirl.create :bundle_item
      @part1 = FactoryGirl.create :bundle_item_part
      @part2 = FactoryGirl.create :bundle_item_part
      @bundle_item.bundle_item_parts << @part1
      @bundle_item.bundle_item_parts << @part2
      @bundle_item.update_num_parts
    end

    it "returns status of OUT_OF_STOCK when all parts have been removed" do
      parts_to_remove = [ @part1.id, @part2.id ]
      @bundle_item.remove_parts( parts_to_remove )
      expect(@bundle_item.status).to eql InventoryItem::OUT_OF_STOCK
    end

    it "returns status of PARTIAL_STOCK when only some parts have been removed" do
      parts_to_remove = [ @part1.id ]
      @bundle_item.remove_parts( parts_to_remove )
      expect(@bundle_item.status).to eql InventoryItem::PARTIAL_STOCK
    end
  end

  describe ".add_existing_parts" do
    before(:each) do
      @bundle_item = FactoryGirl.create :bundle_item
      @part1 = FactoryGirl.create :bundle_item_part
      @part2 = FactoryGirl.create :bundle_item_part
      @bundle_item.bundle_item_parts << @part1
      @bundle_item.bundle_item_parts << @part2
      @bundle_item.update_num_parts
    end

    it "returns a status of IN_STOCK when all parts have been added again" do
      @bundle_item.remove_parts( [ @part1.id, @part2.id ] )
      @bundle_item.add_existing_parts( [ @part1.id, @part2.id ] )
      expect(@bundle_item.status).to eql InventoryItem::IN_STOCK
    end

    it "returns a status of PARTIAL_STOCK when one of two parts has been added again" do
      @bundle_item.remove_parts( [ @part1.id, @part2.id ] )
      @bundle_item.add_existing_parts( [ @part1.id ] )
      expect(@bundle_item.status).to eql InventoryItem::PARTIAL_STOCK
    end
  end

end
