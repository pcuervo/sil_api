require 'spec_helper'

RSpec.describe InventoryTransaction, type: :model do
  let(:inventory_transaction) { FactoryBot.build :inventory_transaction }
  subject { inventory_transaction }

  it { should respond_to(:inventory_item_id) }
  it { should respond_to(:concept) }
  it { should respond_to(:additional_comments) }

  it { should validate_presence_of :inventory_item }
  it { should validate_presence_of :concept }

  it { should belong_to :inventory_item }

  describe '.check_ins' do
    before(:each) do
      3.times { FactoryBot.create :check_in_transaction }
    end

    it 'returns 3 records of type CheckInTransaction' do
      check_ins = InventoryTransaction.check_ins
      expect(check_ins['inventory_transactions'].count).to eql 3
    end
  end

  describe '.check_outs' do
    before(:each) do
      3.times { FactoryBot.create :check_out_transaction }
    end

    it 'returns 3 records of type CheckInTransaction' do
      check_outs = InventoryTransaction.check_outs
      expect(check_outs['inventory_transactions'].count).to eql 3
    end
  end

  describe 'self.next_checkout_folio' do
    it 'returns the next folio when there are no previous transactions' do
      expect(InventoryTransaction.next_checkout_folio).to eql 'FS-0000001'
    end

    it 'returns the next folio when there are no previous transactions' do
      FactoryBot.create :check_out_transaction
      expect(InventoryTransaction.next_checkout_folio).to eql 'FS-0000002'
    end
  end

  describe 'self.next_checkin_folio' do
    it 'returns the next folio when there are no previous transactions' do
      expect(InventoryTransaction.next_checkin_folio).to eql 'FE-0000001'
    end

    it 'returns the next folio when there is one transaction without assigned folio' do
      FactoryBot.create :check_in_transaction
      expect(InventoryTransaction.next_checkin_folio).to eql 'FE-0000002'
    end

    it 'returns the next folio when there are previous transactions' do
      check_in = FactoryBot.create :check_in_transaction
      check_in.update_attribute(:folio, InventoryTransaction.next_checkin_folio)

      expect(InventoryTransaction.next_checkin_folio).to eql 'FE-0000003'
    end
  end
end
