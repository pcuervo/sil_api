class LeanTransactionSerializer < ActiveModel::Serializer
  attributes :id, :inventory_item, :concept, :additional_comments, :created_at, :actable_type, :quantity, :specific
end
