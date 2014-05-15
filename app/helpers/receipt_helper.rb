module ReceiptHelper
  def as_currency(value)
    "$#{'%.2f' % (value.to_f/100.0)}"
  end

  def line_description(line)
    line["description"] || "Subscription to #{line['plan']['name']}"
  end
end
