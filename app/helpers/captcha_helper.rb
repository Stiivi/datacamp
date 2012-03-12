# -*- encoding : utf-8 -*-
module CaptchaHelper
  def verify_captcha_for(model)
    verify_recaptcha(private_key: Datacamp::Config.get(:captcha_private_key), model: model)
  end
end
