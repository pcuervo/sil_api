require 'spec_helper'

RSpec.describe DeliveryRequest, type: :model do
  describe '.authorize' do
    let(:delivery_request) { create_delivery_request(1) }
    let(:litobel_supplier) { create_litobel_supplier }
    let(:delivery_guy) { FactoryGirl.create(:user, role: User::DELIVERY) }

    it 'returns true when the delivery request has been authorized and quantities were not modified' do
      delivery_request.authorize(delivery_guy.id, litobel_supplier.id, 'adicionales')

      puts DeliveryRequest.all.count.to_yaml
      expect(DeliveryRequest.all.count).to eql 0
      expect(DeliveryRequestItem.all.count).to eql 0
      expect(Delivery.all.count).to eql 1
    end
  end
end
