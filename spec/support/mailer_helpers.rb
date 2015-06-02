module MailerHelpers
  def last_email
    ActionMailer::Base.deliveries.last
  end

  def reset_email
    ActionMailer::Base.deliveries = []
  end

  def email_recipients
    ActionMailer::Base.deliveries.map(&:to).flatten
  end

  def emails
    ActionMailer::Base.deliveries
  end
end

RSpec.configure do |config|
  config.include MailerHelpers
end