require 'spec_helper'

RSpec.describe Supplier, type: :model do
  let(:supplier){ FactoryGirl.create :supplier }
  subject{ supplier }

  it { should validate_presence_of :name }
  it { should validate_uniqueness_of :name }
end


