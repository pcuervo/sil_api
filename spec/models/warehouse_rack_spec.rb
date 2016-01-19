require 'spec_helper'

RSpec.describe WarehouseRack, type: :model do
  let(:warehouse_rack) { FactoryGirl.create :warehouse_rack }
  subject { warehouse_rack }

  it { should respond_to(:name) }
  it { should respond_to(:row) }
  it { should respond_to(:column) }

  it { should validate_uniqueness_of :name }

  it { should have_many(:warehouse_locations) }

  describe ".available_locations" do
    before(:each) do
      @warehouse_rack = FactoryGirl.create :warehouse_rack
      5.times do |i|

        location = FactoryGirl.create :warehouse_location
        if i == 1
          location.status = 3
        end
        @warehouse_rack.warehouse_locations << location


      end
    end

    context "successfully retrieve available locations" do
      it "return a hash containing available locations" do
        locations_response = @warehouse_rack.available_locations
        puts locations_response.to_yaml
        expect( locations_response['available_locations'].count ).to eq 5
      end
    end
  end

end
