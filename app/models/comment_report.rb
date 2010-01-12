class CommentReport < ActiveRecord::Base
  belongs_to :comment
  
  cattr_reader :types
  
  @@types = {
    I18n.t("comments.spam_report") => :spam,
    I18n.t("comments.violation_report") => :violation
  }
end
