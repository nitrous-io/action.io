namespace :actionio do
  task new_team_plans: :environment do
    if (team_plan_group = PlanGroup.find_by_name(PlanGroup::TEAM_NAME))
      plans = team_plan_group.plans
      plans.each do |plan|
        begin
          Stripe::Plan.create(
            amount: plan.price_in_cents,
            interval: plan.interval,
            name: plan.name,
            currency: 'usd',
            id: plan.stripe_id
          )

          puts "Created Plan: #{plan.name}"
        rescue => e
          puts e
        end
      end
    end
  end

  task new_personal_plans: :environment do
    start_plan = Plan.create name: 'Start', price: 7.95,  n2o_amount: 400,  interval: 'month', stripe_id: 'n2o_400',  cpu_multiplier: 1, vmem_multiplier: 1, memory: 2, storage: 16, features: [{"name" => "1 Box", "live" => true}, {"name" => "Boxes Never Shutdown", "live" => true}], display_order: 1
    shift_plan = Plan.create name: 'Shift', price: 19.95, n2o_amount: 1000, interval: 'month', stripe_id: 'n2o_1000', cpu_multiplier: 2, vmem_multiplier: 2, memory: 4, storage: 32, features: [{"name" => "3 Boxes", "live" => true}, {"name" => "Boxes Never Shutdown", "live" => true}, {"name" => "Custom Domains", "live" => true}], display_order: 2, highlight: true
    turbo_plan = Plan.create name: 'Turbo', price: 39.95, n2o_amount: 2000, interval: 'month', stripe_id: 'n2o_2000', cpu_multiplier: 2, vmem_multiplier: 2, memory: 8, storage: 64,  features: [{"name" => "5 Boxes", "live" => true}, {"name" => "Boxes Never Shutdown", "live" => true}, {"name" => "Custom Domains", "live" => true}], display_order: 3

    plans = [start_plan, shift_plan, turbo_plan]

    plans.each do |plan|
      begin
        Stripe::Plan.create(
          amount: plan.price_in_cents,
          interval: plan.interval,
          name: plan.name,
          currency: 'usd',
          id: plan.stripe_id
        )
      rescue => e
        puts e
      end
    end

    global_plan_group = PlanGroup.find_by_name(PlanGroup::DEFAULT_NAME)

    # Remove existing plans
    global_plan_group.plan_group_memberships.destroy_all

    # Add new plans
    global_plan_group.plans << start_plan
    global_plan_group.plans << shift_plan
    global_plan_group.plans << turbo_plan
  end

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

  task create_edu_plus_plan: :environment do
    edu_spl_plan = Plan.find_by_stripe_id('n2o_18500')
    if edu_spl_plan.nil?
      edu_spl_plan = Plan.create name: 'Education Plus',
                                      price: 299.99,
                                      n2o_amount: 18500,
                                      interval: 'month',
                                      stripe_id: 'n2o_18500',
                                      cpu_multiplier: 2,
                                      vmem_multiplier: 2,
                                      memory: 32, storage: 256,
                                      features: "Custom Domains",
                                      display_order: 4
      begin
        Stripe::Plan.create(
          amount: edu_spl_plan.price_in_cents,
          interval: edu_spl_plan.interval,
          name: edu_spl_plan.name,
          currency: 'usd',
          id: edu_spl_plan.stripe_id
        )
      rescue => e
        puts e
      end
    end
  end

  task create_edu_spl_plan: :environment do
    edu_spl_pg_name = 'Education Special Plan'

    edu_spl_pg = PlanGroup.find_by_name(edu_spl_pg_name)
    if edu_spl_pg.nil?
      edu_spl_pg = PlanGroup.create(name: edu_spl_pg_name)
    end

    start_plan = Plan.find_by_stripe_id('n2o_600')
    shift_plan = Plan.find_by_stripe_id('n2o_1200')
    turbo_plan = Plan.find_by_stripe_id('n2o_2500')

    edu_spl_plan = Plan.find_by_stripe_id('n2o_12500')
    if edu_spl_plan.nil?
      edu_spl_plan = Plan.create name: 'Education Special',
                                      price: 199.99,
                                      n2o_amount: 12500,
                                      interval: 'month',
                                      stripe_id: 'n2o_12500',
                                      cpu_multiplier: 2,
                                      vmem_multiplier: 2,
                                      memory: 32, storage: 256,
                                      features: "Custom Domains",
                                      display_order: 4
      begin
        Stripe::Plan.create(
          amount: edu_spl_plan.price_in_cents,
          interval: edu_spl_plan.interval,
          name: edu_spl_plan.name,
          currency: 'usd',
          id: edu_spl_plan.stripe_id
        )
      rescue => e
        puts e
      end
    end

    p start_plan
    p shift_plan
    p turbo_plan
    p edu_spl_plan

    edu_spl_pg.plans << start_plan
    edu_spl_pg.plans << shift_plan
    edu_spl_pg.plans << turbo_plan
    edu_spl_pg.plans << edu_spl_plan
  end

  task lamp_camp_spl_plans: :environment do
    edu_spl_pg_name = 'LAMP Camp Special Plan'

    edu_spl_pg = PlanGroup.find_by_name(edu_spl_pg_name)
    if edu_spl_pg.nil?
      edu_spl_pg = PlanGroup.create(name: edu_spl_pg_name)
    end

    start_plan = Plan.find_by_stripe_id('n2o_400')
    shift_plan = Plan.find_by_stripe_id('n2o_1000')
    turbo_plan = Plan.find_by_stripe_id('n2o_2000')

    edu_spl_plan = Plan.find_by_stripe_id('n2o_8000')
    if edu_spl_plan.nil?
      edu_spl_plan = Plan.create name: 'Nitro',
                                      price: 199.99,
                                      n2o_amount: 8000,
                                      interval: 'month',
                                      stripe_id: 'n2o_8000',
                                      cpu_multiplier: 2,
                                      vmem_multiplier: 2,
                                      memory: 32, storage: 256,
                                      features: [{"name" => "40 Boxes", "live" => true}, {"name" => "Boxes Never Shutdown", "live" => true}, {"name" => "Box Snapshots", "live" => true }, {"name" => "Team Management", "live" => false}, {"name" => "Streamlined Dashboard", "live" => false}],
                                      display_order: 4
      begin
        Stripe::Plan.create(
          amount: edu_spl_plan.price_in_cents,
          interval: edu_spl_plan.interval,
          name: edu_spl_plan.name,
          currency: 'usd',
          id: edu_spl_plan.stripe_id
        )
      rescue => e
        puts e
      end
    end

    p start_plan
    p shift_plan
    p turbo_plan
    p edu_spl_plan

    edu_spl_pg.plans << start_plan
    edu_spl_pg.plans << shift_plan
    edu_spl_pg.plans << turbo_plan
    edu_spl_pg.plans << edu_spl_plan
  end

  task serialize_plan_features: :environment do
    Plan.transaction do
      Plan.find_each do |pl|
        raw_features = pl.read_attribute(:features)
        if raw_features.is_a?(Array)
          puts "Plan #{pl.id} features already array, skipping"
          next
        end

        case raw_features
        when ''
          pl.features = []
        when 'Custom Domains'
          pl.features = [{'name' => 'Custom Domains', 'live' => true}]
        else
          puts "Please deal with plan #{pl.id} manually"
        end
        pl.save! if pl.changed?
      end
    end
  end
end
