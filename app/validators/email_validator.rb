class EmailValidator < ActiveModel::Validator
  def validate(record)
    invalid_mail_provider_regex = /#{EMAIL_BLACKLIST.map{ |e| e.gsub(/\./, '\.') }.join('|')}/

    if email = record.email
      if email.match invalid_mail_provider_regex
        record.errors[:email] = "is invalid"
      elsif email_addendum = (email.match(/\+(.*?)@/) || [])[1]
        stripped_email = email.gsub(/\+#{email_addendum}/, '')
        record.errors[:email] = "has already been taken" if User.find_by_email(stripped_email).present?
      end
    end
  end
end
