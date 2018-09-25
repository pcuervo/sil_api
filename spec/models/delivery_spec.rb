require 'spec_helper'

describe Delivery, type: :model do
  let(:delivery) { FactoryBot.create :delivery }

  it { should validate_presence_of :company }
  it { should validate_presence_of :addressee }
  it { should validate_presence_of :address }

  it { should belong_to :user }

  describe '.add_items' do
    before(:each) do
      create_litobel_supplier
      @items = []
      3.times do |_t|
        delivery_item = {}
        item = FactoryBot.create :inventory_item

        delivery_item[:item_id] = item.id
        delivery_item[:quantity] = 1

        @items.push(delivery_item)
      end
    end

    it 'creates 2 DeliveryItems' do
      delivery.add_items(@items, 'El Chomper', 'No comments')
      expect(DeliveryItem.all.count).to eq 3
    end

    it 'register InventoryTransaction with folio' do
      delivery.add_items(@items, 'El Chomper', 'No comments')
      first_transaction_folio = CheckOutTransaction.first.folio
      expect(first_transaction_folio).to eq 'FS-0000001'
    end
  end

  describe '.withdrawn_items_locations' do
    before(:each) do
      create_litobel_supplier

      @items = []
      2.times do |_t|
        delivery_item = {}
        location = FactoryBot.create :warehouse_location
        item = FactoryBot.create :inventory_item
        location.locate(item, 1)

        delivery_item[:item_id] = item.id
        delivery_item[:quantity] = 1
        @items.push(delivery_item)
      end
    end

    it 'returns WarehouseLocations from which delivery Items where removed' do
      delivery.add_items(@items, 'El Chomper', 'No comments')
      delivery.withdrawn_items_locations

      expect(3).to eq 3
    end
  end

  describe 'Delivery.by_keyword' do
    let(:another_delivery) { FactoryBot.create :delivery }
    before(:each) do
      create_litobel_supplier

      @items = []
      3.times do |t|
        delivery_item = {}
        item = FactoryBot.create :inventory_item
        item.update(name: 'MiItem' + t.to_s)

        delivery_item[:item_id] = item.id
        delivery_item[:quantity] = 1
        @items.push(delivery_item)
      end

      delivery.add_items(@items, 'El Chomper', 'No comments')
      @other_items = [@items.first]
      another_delivery.add_items(@other_items, 'El Mamfred', 'With comments')
    end

    it 'returns Deliveries that include the searched InventoryItems' do
      params = { keyword: 'miitem' }
      deliveries = Delivery.by_keyword(params)

      expect(deliveries.first['company']).to eq delivery.company
      expect(deliveries.count).to eq 2
    end
  end
end
