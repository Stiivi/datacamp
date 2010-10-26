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
end