require 'spec_helper'

RSpec.describe InventoryItemRequest, type: :model do
  let(:inventory_item_request) { FactoryGirl.build :inventory_item_request }
  subject { inventory_item_request }

  it { should respond_to(:name) }
  it { should respond_to(:description) }

  # Required fields
  it { should validate_presence_of :name }
  it { should validate_presence_of :project_id }
  it { should validate_presence_of :pm_id }
  it { should validate_presence_of :ae_id }
  it { should validate_presence_of :item_type }

  describe '.details' do
    before(:each) do
      project = FactoryGirl.create :project
      ae = FactoryGirl.create :user
      pm = FactoryGirl.create :user
      3.times.each do
        item_request = FactoryGirl.create :inventory_item_request
        item_request.project_id = project.id
        item_request.pm_id = pm.id
        item_request.ae_id = ae.id
        item_request.save
      end
    end

    it 'returns the most updated records' do
      expect(InventoryItemRequest.details['inventory_item_requests'].count).to eq 3
    end
  end
end
