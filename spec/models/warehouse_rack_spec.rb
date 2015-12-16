require 'spec_helper'

RSpec.describe WarehouseRack, type: :model do
  let(:warehouse_rack) { FactoryGirl.create :warehouse_rack }
  subject { warehouse_rack }

  it { should respond_to(:name) }
  it { should respond_to(:row) }
  it { should respond_to(:column) }

  it { should validate_uniqueness_of :name }

  it { should have_many(:warehouse_locations) }

end
