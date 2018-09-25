require 'spec_helper'

RSpec.describe ItemType, type: :model do
  let(:item_type) { FactoryBot.create :item_type }
  subject { item_type }

  it { should respond_to(:name) }

  it { should validate_uniqueness_of :name }
  it { should validate_presence_of :name }
end
