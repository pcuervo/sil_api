require 'spec_helper'

describe BulkItem, type: :model do
  let(:bulk_item) { FactoryGirl.create :bulk_item }
  subject { bulk_item }

  it { should respond_to(:name) }
  it { should respond_to(:description) }
  it { should respond_to(:image_url) }
  it { should respond_to(:status) }
  it { should respond_to(:item_type) }
  it { should respond_to(:barcode) }
  it { should respond_to(:quantity) }
  it { should respond_to(:state) }
  it { should respond_to(:value) }
  

end
