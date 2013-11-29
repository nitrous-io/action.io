module ReceiptHelper
  def as_currency(value)
    "USD#{'%.2f' % (value.to_f/100.0)}"
  end

  def formatted_date(value)
    if value.is_a? Time
      value.strftime("%d %B %Y")
    end
  end
end
