require 'spec_helper'

RSpec.describe WithdrawRequestItem, type: :model do
  let(:withdraw_request_item) { FactoryGirl.build :withdraw_request_item }
  subject { withdraw_request_item }

  it { should belong_to :withdraw_request }
  it { should belong_to :inventory_item }

end
