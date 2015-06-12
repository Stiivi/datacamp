# -*- encoding : utf-8 -*-
class Comment < ActiveRecord::Base
  belongs_to :user
  belongs_to :dataset_description
  belongs_to :parent_comment, :class_name => "Comment"
  
  has_many :comment_ratings
  has_many :comment_reports
  
  default_scope where(is_suspended: nil)

  validates_presence_of :user, :dataset_description

  def self.find_include_suspended conditions=''
    unscoped.where(conditions)
  end

  def self.within_all
    unscoped
  end
  
  ##############################################################################
  # Method to count rating
  def score
    (count_positive_ratings || 0) - (count_negative_ratings || 0)
  end
  
  def total_ratings
    (count_positive_ratings || 0) + (count_negative_ratings || 0)
  end
  
  def added_by_staff?
    user && user.has_privilege?(:social_moderating)
  end
  
  def score_html_class
    if added_by_staff?
      return "staff"
    end
    
    rating = score
        
    if rating > 0
      rating > 10 ? "positive positive_10" : "positive positive_#{rating.to_i}"
    elsif rating < 0
      rating < -10 ? "negative negative_10" : "negative negative_#{rating.abs.to_i}"
    else
      "neutral"
    end
  end
  
  def rated_by_user? user
    comment_ratings.where(:user_id => user.id).first ? true : false
  end
  
  ##############################################################################
  # Score reloading
  def reload_score
    self.count_positive_ratings = CommentRating.where(comment_id: id, value: 1).count
    self.count_negative_ratings = CommentRating.where(comment_id: id, value: -1).count
    self.save
    # self.score = eval comment_ratings.collect{|rating|rating.value}.join("+")
  end
  
  ##############################################################################
  # Path
  def return_path
    show_dataset_path(dataset_description)
  end
end
