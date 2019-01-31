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

  describe '.cancel_checkout_folio' do
    context 'when successful' do
      let(:num_items){ 5 }
      let(:user){ FactoryBot.create(:user) }
      let(:item_data) { csv_load_attributes(num_items) }
      let(:inventory_loader){ InventoryLoad.new(user, item_data) }
      let(:litobel){ Supplier.find_or_create_by(name: 'Litobel') }
      let(:folio){ InventoryTransaction.next_checkout_folio }

      before do
        inventory_loader.load 

        InventoryItem.all.each do |item|
          item.withdraw(
            Date.today, 
            '', 
            litobel.id, 
            '', 
            'This is a test', 
            item.quantity, 
            folio
          )
        end
      end

      it 'should return folio InventoryItems and locate in previous location' do
        InventoryTransaction.cancel_checkout_folio(folio)
        in_stock = InventoryItem.where(status: 1)

        expect(in_stock.count).to eq num_items
        expect(CheckInTransaction.count).to eq num_items*2
        expect(CheckOutTransaction.count).to eq num_items
        expect(ItemLocation.count).to eq num_items
      end
    end

    context 'when not successful' do
      context 'folio not found' do
        it 'should raise error if folio not found' do
          expect{ InventoryTransaction.cancel_checkout_folio('fakefolio') }.to raise_error(SilExceptions::InvalidFolio)
        end
      end
    end
  end

  describe '.cancel_checkin_folio' do
    context 'when successful' do
      let(:num_items){ 5 }
      let(:user){ FactoryBot.create(:user) }
      let(:item_data) { csv_load_attributes(num_items) }
      let(:inventory_loader){ InventoryLoad.new(user, item_data) }
      let(:litobel){ Supplier.find_or_create_by(name: 'Litobel') }

      before { inventory_loader.load } 

      it 'should withdraw Items' do
        folio = CheckInTransaction.last.folio
        InventoryTransaction.cancel_checkin_folio(folio)
        out_of_stock = InventoryItem.where(status: 2)

        expect(out_of_stock.count).to eq num_items
        expect(CheckInTransaction.count).to eq num_items
        expect(CheckOutTransaction.count).to eq num_items
        expect(ItemLocation.count).to eq 0
      end
    end

    context 'when not successful' do
      context 'folio not found' do
        it 'should raise error if folio not found' do
          expect{ InventoryTransaction.cancel_checkin_folio('fakefolio') }.to raise_error(SilExceptions::InvalidFolio)
        end
      end
    end
  end
end
