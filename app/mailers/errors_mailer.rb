class ErrorsMailer < ActionMailer::Base
  def error_report_mail(user, url, item, description)
    @user = user
    @url = url
    @item = item
    @description = description
    mail(from: SystemVariable.get("site_name", "Datacamp"), to: Datacamp::Application.config.admin_emails, subject: 'Hlasenie o chybe', content_type: 'text/html')
  end
end
