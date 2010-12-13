# -*- encoding : utf-8 -*-
class UserMailer < ActionMailer::Base
  
  def forgot_password(user)
    recipients user.email
    # FIXME: SYSTEM: from as system configurable variable, default: no-reply@localhost
    from SystemVariable.get("site_name", "Datacamp")
    subject I18n.t("users.restore_mail_subject")
    body :user => user
    content_type "text/html"
  end

end
