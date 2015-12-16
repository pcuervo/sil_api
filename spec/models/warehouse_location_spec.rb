require 'spec_helper'

describe WarehouseLocation, type: :model do
  before { @warehouse_location = FactoryGirl.build(:warehouse_location) }


  it { should respond_to(:name) }
  it { should respond_to(:units) }
  it { should respond_to(:status) }

  it { should belong_to(:warehouse_rack) }
  it { should have_many(:item_locations) }
  it { should validate_uniqueness_of :name }
  it { should validate_presence_of :name }

end
