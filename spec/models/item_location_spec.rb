require 'spec_helper'

RSpec.describe ItemLocation, type: :model do
    before { @warehouse_location = FactoryGirl.build(:warehouse_location) }

    it { should respond_to(:quantity) }
    it { should respond_to(:units) }
    it { should respond_to(:part_id) }

    it { should belong_to(:warehouse_location) }
    it { should belong_to(:inventory_item) }
    
end