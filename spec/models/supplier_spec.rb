require 'spec_helper'

RSpec.describe Supplier, type: :model do
  let(:supplier) { FactoryBot.create :supplier }
  subject { supplier }

  it { should validate_presence_of :name }
  it { should validate_uniqueness_of :name }
end
