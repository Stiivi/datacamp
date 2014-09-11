# -*- encoding : utf-8 -*-
class UserMailer < ActionMailer::Base
  layout 'mailer'
  
  def registration_complete(user)
    @user = user

    attachments.inline['logo.jpg'] = File.read Rails.root.join('app','assets','images','logo_AFP.jpg')

    mail(from: SystemVariable.get("site_name", "Datacamp"), to: user.email, subject: I18n.t("email.registration_complete.subject"), content_type: "text/html")
  end
  
  def forgot_password(user)
    @user = user
    mail(from: SystemVariable.get("site_name", "Datacamp"), to: user.email, subject: I18n.t("users.restore_mail_subject"), content_type: "text/html")
  end

end
