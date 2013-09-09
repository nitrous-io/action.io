FactoryGirl.define do
  factory :receipt do
    period_start    1380585600
    period_end      1383177600
    lines [{
      "amount" => 500,
      "currency" => "usd",
      "quantity" => 1,
      "description" => nil,
      "period" => {
        "start" => 1380585600,
        "end" => 1383177600
      },
      "plan" => {
        "name" => "500 N2O"
      }
    }]
    subtotal        500
    total           500

    billing_profile   { create :billing_profile, plan: create(:subscription_plan) }
  end
end
