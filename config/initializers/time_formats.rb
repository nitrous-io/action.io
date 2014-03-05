Time::DATE_FORMATS[:short_ordinal] = lambda { |time| time.strftime("%B #{time.day.ordinalize}") }
Time::DATE_FORMATS[:billing_period] = lambda { |time| time.strftime("%b %d, %Y") }
