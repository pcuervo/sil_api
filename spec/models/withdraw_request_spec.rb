require 'spec_helper'

RSpec.describe WithdrawRequest, type: :model do
  before { @withdraw_request = FactoryBot.build(:withdraw_request) }

  it { should respond_to(:exit_date) }
  it { should respond_to(:pickup_company_id) }

  it { should belong_to :user }
  it { should have_many(:withdraw_request_items) }

  describe '.update_items_status_to_pending' do
    before(:each) do
      @withdraw_request = FactoryBot.create :withdraw_request
      @withdraw_request_item = FactoryBot.create :withdraw_request_item
      @inventory_item = FactoryBot.create :inventory_item
      @withdraw_request_item.inventory_item = @inventory_item
      @withdraw_request_item.save!
      @withdraw_request.withdraw_request_items << @withdraw_request_item
      @withdraw_request.save!
    end

    it 'returns the most updated records' do
      @withdraw_request.update_items_status_to_pending
      expect(InventoryItem.last.status).to eql InventoryItem::PENDING_WITHDRAWAL
    end
  end

  describe '.authorize' do
    before(:each) do
      @withdraw_request_item = FactoryBot.create :withdraw_request_item
      @withdraw_request = @withdraw_request_item.withdraw_request
      @inventory_item = FactoryBot.create :inventory_item

      @withdraw_request_item.inventory_item = @inventory_item
      @withdraw_request_item.save
      @withdraw_request.withdraw_request_items << @withdraw_request_item
      @withdraw_request.save
    end

    it 'returns true when the withdraw request has been authorized' do
      authorized = @withdraw_request.authorize(Time.now, 'adicionales')
      expect(authorized).to eql true
      expect(WithdrawRequest.all.count).to eql 0
      expect(WithdrawRequestItem.all.count).to eql 0
    end
  end
end
