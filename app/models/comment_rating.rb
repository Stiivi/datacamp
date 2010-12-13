# -*- encoding : utf-8 -*-
class CommentRating < ActiveRecord::Base
  
  belongs_to :comment
  
  def after_save
    comment.reload_score if comment
    #     comment.user.reload_score if comment and comment.user
  end
  
end
