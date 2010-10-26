module CaptchaHelper
  def verify_captcha_for(model)
    if Rails.env.production?
      verify_recaptcha(
        :private_key => Datacamp::Config.get(:captcha_private_key),
        :model => model
      )
    else
      true
    end
  end
end