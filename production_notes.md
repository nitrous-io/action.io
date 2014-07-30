# Production Notes

This file is for changes or decisions made for running production instance.
Most likely to be payment-related since those are changes that cannot be
smoothed over by db workarounds.


## 20140730111329PDT Plan downgrades not taking effect in db

https://github.com/nitrous-io/action.io/pull/740

1. Subscriptions with pending_plan_id = plan_id, update pending_plan_id to null

```ruby
Subscription.where('pending_plan_id = plan_id').each {|sub| sub.update_column(:pending_plan_id, nil) }

# lost irb output, ids are
bad = [67, 103, 257, 407, 402, 601, 483, 520, 676, 834, 820, 765, 767, 821, 748, 850, 394, 287, 97, 390, 892, 911, 777, 855, 52, 869, 969, 995, 959, 996, 830, 264, 866]
```

2. Reset `payment_due` field on those subscriptions where last invoice was paid

```ruby
invs = Subscription.where(:id => bad).map {|sub| Stripe::Invoice.all(customer: s.user.stripe_customer_id, limit:1)["data"][0] }
irb(main):017:0> invs.map {|inv| inv["paid"] }
=> [true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true, true]
irb(main):041:0> Subscription.where(:id => bad).each {|sub| sub.update_column(:payment_due, false) }
```

3. Determine subscriptions where Stripe plans do not match db plans

```ruby
irb(main):026:0> cuses = Subscription.where(:id => bad).map {|sub| [sub, Stripe::Customer.retrieve(s.user.stripe_customer_id)] } ; nil
=> nil
irb(main):029:0> needsfix = cuses.select {|sub, stripe| sub.plan.stripe_id != stripe[:subscription][:plan][:id] }.map {|sub, stripe| "#{sub.id}: #{sub.plan.stripe_id} -> #{stripe[:subscription][:plan][:id]}" } ; nil
=> nil
irb(main):030:0> needsfix
=> ["52: n2o_6000 -> n2o_1000", "103: n2o_2000 -> n2o_1000", "264: n2o_400 -> n2o_1000", "390: n2o_2000 -> n2o_1000", "394: n2o_2000 -> n2o_1000", "767: n2o_2000 -> n2o_1000", "777: n2o_2000 -> n2o_1000", "821: n2o_2000 -> n2o_1000", "892
: n2o_2000 -> n2o_1000"]

# Note: Sub id 52 is Greg, can ignore

irb(main):034:0> needs_downgrade_sub_ids = [103, 390, 394, 767, 777, 821, 892]
=> [103, 390, 394, 767, 777, 821, 892]
irb(main):035:0> Subscription.where(:id => _).map {|sub| [sub.user.used_n2o, sub.plan.stripe_id] }
=> [[1385, "n2o_2000"], [2150, "n2o_2000"], [2285, "n2o_2000"], [1360, "n2o_2000"], [1400, "n2o_2000"], [1170, "n2o_2000"], [0, "n2o_2000"]]
irb(main):036:0> Subscription.where(:id => _).map {|sub| [sub.id, sub.user.used_n2o, sub.plan.stripe_id] }
=> []
irb(main):037:0> Subscription.where(:id => needs_downgrade_sub_ids).map {|sub| [sub.id, sub.user.used_n2o, sub.plan.stripe_id] }
=> [[103, 1385, "n2o_2000"], [390, 2150, "n2o_2000"], [394, 2285, "n2o_2000"], [767, 1360, "n2o_2000"], [777, 1400, "n2o_2000"], [821, 1170, "n2o_2000"], [892, 0, "n2o_2000"]]

```

**All but one of these users are over the 1000 N2O mark; decision made to
continue giving them the free benefit as opposed to spending time to
communicate with them and get them to free up N2O before downgrading.**

4. Two users contacted support about downgrades not taking effect

```ruby
# run the contents of Subscription#change_plan! without notifications

ActiveRecord::Base.transaction do
  u = User.find(60290)
  s = u.subscription
  s.send(:empty_n2o!)
  s.send(:archive_past_subscription)
  s.plan = Plan.find(11)
  s.save!
  s.send(:fill_n2o!)
end

ActiveRecord::Base.transaction do
  u = User.find(29770)
  s = u.subscription
  s.send(:empty_n2o!)
  s.send(:archive_past_subscription)
  s.plan = Plan.find(12)
  s.save!
  s.send(:fill_n2o!)
end
```

Note that user 29770 was over N2O quota for downgraded plan.
