require 'spec_helper'

describe BundleItemPart, type: :model do
  let(:bundle_item_part) { FactoryGirl.create :bundle_item_part }
  subject { bundle_item_part }

  it { should respond_to(:name) }
  it { should respond_to(:serial_number) }
  it { should respond_to(:brand) }
  it { should respond_to(:model) }

  it { should belong_to(:bundle_item) }
  it { should validate_uniqueness_of :serial_number }
  it { should validate_presence_of :name }
  it { should validate_presence_of :serial_number }
end
