require 'spec_helper'

describe MailchimpController do
  specify { expect(post: '/mailchimp/webhook').to route_to controller: 'mailchimp', action: 'webhook', format: "json" }
end
