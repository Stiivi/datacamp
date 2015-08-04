if Rails.env.production? && ENV['DATANEST_GMAIL_USER'].present? && ENV['DATANEST_GMAIL_PASSWORD'].present?
  ActionMailer::Base.delivery_method = :smtp
  ActionMailer::Base.smtp_settings = {
    :enable_starttls_auto => true,
    :address => 'smtp.gmail.com',
    :port => "587",
    :authentication => :plain,
    :domain => 'fair-play.sk',
    :user_name => ENV['DATANEST_GMAIL_USER'],
    :password => ENV['DATANEST_GMAIL_PASSWORD']
  }
end
