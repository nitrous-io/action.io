module PricingHelper
  def featuresArray(plan)
    plan.features.strip.split('|')
  end
end
