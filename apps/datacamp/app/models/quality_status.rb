class QualityStatus < ActiveRecord::Base
  
  def title
    I18n.t("quality_statuses.#{name}")
  end
  
end