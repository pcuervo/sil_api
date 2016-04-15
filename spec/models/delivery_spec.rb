require 'spec_helper'

describe Delivery, type: :model do
  before { @delivery = FactoryGirl.build(:delivery) }

  it { should validate_presence_of :delivery_user_id }
  it { should validate_presence_of :company }
  it { should validate_presence_of :addressee }
  it { should validate_presence_of :address }

  it { should belong_to :user }
end
