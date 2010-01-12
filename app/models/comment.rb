class Comment < ActiveRecord::Base
  belongs_to :user
  belongs_to :dataset_description
  belongs_to :parent_comment, :class_name => "Comment"
  
  has_many :comment_ratings
  has_many :comment_reports
  
  default_scope :conditions => { :is_suspended => nil }

  def self.find_include_suspended *args
    self.with_exclusive_scope { find(*args) }
  end
  
  def self.find_by_id! id
    with_exclusive_scope { super(id) }
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
    user.has_privilege?(:social_moderating)
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
    comment_ratings.find(:first, :conditions => {:user_id => user.id}) ? true : false
  end
  
  ##############################################################################
  # Score reloading
  def reload_score
    self.count_positive_ratings = CommentRating.count :conditions => {:comment_id => self.id, :value => 1}
    self.count_negative_ratings = CommentRating.count :conditions => {:comment_id => self.id, :value => -1}
    self.save
    # self.score = eval comment_ratings.collect{|rating|rating.value}.join("+")
  end
  
  ##############################################################################
  # Path
  def return_path
    show_dataset_path(dataset_description)
  end
end