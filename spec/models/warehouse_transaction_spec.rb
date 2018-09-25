require 'spec_helper'

RSpec.describe WarehouseTransaction, type: :model do
  let(:warehouse_transaction) { FactoryBot.create :warehouse_transaction }
  subject { warehouse_transaction }

  it { should respond_to(:quantity) }
  it { should respond_to(:concept) }

  it { should belong_to(:warehouse_location) }
  it { should belong_to(:inventory_item) }
end
