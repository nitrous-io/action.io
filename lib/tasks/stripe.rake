namespace :stripe do
  task 'plans:prepare' => 'environment' do
    begin
      Plan.order(:stripe_id).each do |plan|
        Stripe::Plan.create(
          :amount => plan.price_in_cents,
          :interval => plan.interval,
          :name => plan.name,
          :currency => 'usd',
          :id => plan.stripe_id
        )
        puts "Added plan '#{plan.name}' to Stripe."
      end
    rescue => e
      puts e
    end
  end

  desc "Fetch all events from Stripe and populate the revenue_events table."
  task 'fetch_revenue_events' => 'environment' do
    from = Time.new(2013, 11, 1)
    batch_size = 100

    fetch_events_in_batches = lambda do |offset|
      object = Stripe::Event.all created: {gt: from.to_i }, offset: offset, count: batch_size
      events = object.data

      puts "Processing events from #{offset} to #{offset + batch_size}"

      if events.length > 0
        events.each do |event|
          event_type = nil
          amount = nil
          subscription_started_at = nil

          # check if the event is already saved
          next if RevenueEvent.exists?(stripe_id: event.id)

          case event.type
          when 'customer.subscription.created'
            event_type = RevenueEvent::SUBSCRIBED
            amount = event.data.object.plan.amount
            subscription_started_at = Time.at(event.data.object.start)
          when 'customer.subscription.updated'
            new_plan_amount = event.data.object.plan.amount
            old_plan_amount = event.data.previous_attributes.try(:plan).try(:amount)

            next unless old_plan_amount

            price_change = new_plan_amount - old_plan_amount
            event_type = (price_change > 0) ? RevenueEvent::UPGRADED : RevenueEvent::DOWNGRADED
            amount = price_change.abs
            subscription_started_at = Time.at(event.data.object.start)
          when 'customer.subscription.deleted'
            event_type = RevenueEvent::CANCELED
            amount = event.data.object.plan.amount
            subscription_started_at = Time.at(event.data.object.start)
          when 'invoice.created'
            event_type = RevenueEvent::BILLED
            amount = event.data.object.total
          when 'charge.succeeded'
            event_type = RevenueEvent::CHARGED
            amount = event.data.object.amount
          when 'charge.refunded'
            event_type = RevenueEvent::REFUNDED
            amount = event.data.object.amount_refunded
          end

          if event_type && amount
            RevenueEvent.create event: event_type, amount: amount, created_at: Time.at(event.created), stripe_id: event.id, subscription_started_at: subscription_started_at
            puts "Added #{event.id}"
          end
        end
      else
        return
      end

      fetch_events_in_batches.call (offset + batch_size)
    end

    fetch_events_in_batches.call(0)
  end
end
