# -*- encoding : utf-8 -*-
module AccessableHelper
  def accessable_level_name_for_level(level)
    if level == 0
      "restricted"
    elsif level == 1
      "regular"
    elsif level == 2
      "premium"
    end
  end

  def accessable_options_for_select
    Api.access_levels.collect do |level_name, level|
      [
        I18n.t("api.levels.#{level_name.to_s}"),
        level.to_s
      ]
    end
  end
end
