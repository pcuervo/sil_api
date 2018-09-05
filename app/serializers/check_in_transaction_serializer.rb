class CheckInTransactionSerializer < ActiveModel::Serializer
  attributes :id, :quantity, :concept, :additional_comments, :inventory_item, :folio, :created_at
end
