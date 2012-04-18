if Rails.env.development? || Rails.env.test?
  Pusher.app_id = 18741
  Pusher.key = 'adc1605eb3a2e6c83145'
  Pusher.secret = '87794df50b181713e3de'
end
