class Receipt < ActiveRecord::Base
  attr_accessible :period_start, :period_end, :lines, :subtotal, :total
  belongs_to :billing_profile

  serialize :lines, JSON

  after_create :deliver_mail

  def period_start=(value)
    if value.is_a? Integer
      self[:period_start] = Time.at(value)
    end
  end

  def period_end=(value)
    if value.is_a? Integer
      self[:period_end] = Time.at(value)
    end
  end

  private
  def deliver_mail
    ReceiptMailer.delay.send_receipt(id)
  end
end
