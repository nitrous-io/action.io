namespace :actionio do
  task create_double_nitro_edu_plan: :environment do
    double_nitro_edu_pg_name = 'Double Nitro EDU'

    double_nitro_edu_pg = PlanGroup.find_by_name(double_nitro_edu_pg_name)
    if double_nitro_edu_pg.nil?
      double_nitro_edu_pg = PlanGroup.create(name: double_nitro_edu_pg_name)
    end

    start_plan = Plan.find_by_stripe_id('n2o_600')
    shift_plan = Plan.find_by_stripe_id('n2o_1200')
    turbo_plan = Plan.find_by_stripe_id('n2o_2500')

    double_nitro_plan = Plan.find_by_stripe_id('n2o_10000')
    if double_nitro_plan.nil?
      double_nitro_plan = Plan.create name: 'Double Nitro',
                                      price: 159.99,
                                      n2o_amount: 10000,
                                      interval: 'month',
                                      stripe_id: 'n2o_10000',
                                      cpu_multiplier: 2,
                                      vmem_multiplier: 2,
                                      memory: 32, storage: 256,
                                      features: "Custom Domains",
                                      display_order: 4
      begin
        Stripe::Plan.create(
          amount: double_nitro_plan.price_in_cents,
          interval: double_nitro_plan.interval,
          name: double_nitro_plan.name,
          currency: 'usd',
          id: double_nitro_plan.stripe_id
        )
      rescue => e
        puts e
      end
    end

    p start_plan
    p shift_plan
    p turbo_plan
    p double_nitro_plan

    double_nitro_edu_pg.plans << start_plan
    double_nitro_edu_pg.plans << shift_plan
    double_nitro_edu_pg.plans << turbo_plan
    double_nitro_edu_pg.plans << double_nitro_plan
  end
end
