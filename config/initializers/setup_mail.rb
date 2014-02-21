if Rails.env.production? && Datacamp::Config.get(:gmail_user).present? && Datacamp::Config.get(:gmail_password).present?
  require 'tlsmail'
  Net::SMTP.enable_tls(OpenSSL::SSL::VERIFY_NONE)

  ActionMailer::Base.delivery_method = :smtp
  ActionMailer::Base.smtp_settings = {
    :enable_starttls_auto => true,
    :tls => true,
    :address => 'smtp.gmail.com',
    :port => "587",
    :authentication => :plain,
    :domain => Datacamp::Config.get(:gmail_domain),
    :user_name => Datacamp::Config.get(:gmail_user),
    :password => Datacamp::Config.get(:gmail_password)
  }
end
