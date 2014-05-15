class ReceiptSerializer < ActiveModel::Serializer
  attributes :id, :period_start, :period_end,
             :lines, :subtotal, :total
end
