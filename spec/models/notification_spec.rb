require 'spec_helper'

RSpec.describe Notification, type: :model do
  it { should respond_to(:message) }
  it { should respond_to(:status) }
  it { should have_and_belong_to_many :users }
  it { should belong_to :inventory_item }

  it { should validate_presence_of(:title) }
  it { should validate_presence_of(:message) }
end
