# -*- encoding : utf-8 -*-
class CommentRating < ActiveRecord::Base
  
  belongs_to :comment
  
  after_save :reload_score
  
  
  def reload_score
    comment.reload_score if comment
    #     comment.user.reload_score if comment and comment.user
  end 
  
end
