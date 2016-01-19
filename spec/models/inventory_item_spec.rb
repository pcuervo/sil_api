require 'spec_helper'

describe InventoryItem do
  let(:inventory_item) { FactoryGirl.build :inventory_item }
  subject { inventory_item }

  it { should respond_to(:name) }
  it { should respond_to(:description) }
  it { should respond_to(:image_url) }
  it { should respond_to(:status) }

  # Required fields
  it { should validate_presence_of :name }
  it { should validate_presence_of :status }
  it { should validate_presence_of :item_type }

  # Required relations
  it { should validate_presence_of(:user)}
  it { should validate_presence_of(:project) }

  it { should belong_to :user }
  it { should belong_to :project }
  it { should have_many(:item_locations) }

  describe ".recent" do
    before(:each) do
      @inventory_item1 = FactoryGirl.create :inventory_item
      @inventory_item2 = FactoryGirl.create :inventory_item
      @inventory_item3 = FactoryGirl.create :inventory_item
      @inventory_item4 = FactoryGirl.create :inventory_item
    end

    it "returns the most updated records" do
      expect(InventoryItem.recent).to match_array([@inventory_item3, @inventory_item2, @inventory_item4, @inventory_item1])
    end
  end

  describe ".search" do
    before(:each) do
      @inventory_item1 = FactoryGirl.create :unit_item
      @inventory_item2 = FactoryGirl.create :bulk_item
      @inventory_item3 = FactoryGirl.create :bundle_item
      @inventory_item4 = FactoryGirl.create :unit_item
    end

    context "when an empty hash is sent" do
      it "returns all the products" do
        
      end
    end
  end
  
end