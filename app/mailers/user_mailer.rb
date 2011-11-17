# -*- encoding : utf-8 -*-
class UserMailer < ActionMailer::Base
  
  def forgot_password(user)
    @user = user
    mail(from: SystemVariable.get("site_name", "Datacamp"), to: user.email, subject: I18n.t("users.restore_mail_subject"), content_type: "text/html")
  end

end
