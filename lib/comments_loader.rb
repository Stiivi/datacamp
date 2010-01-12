module CommentsLoader
  def load_comments
    record_id = @record ? @record.id : nil
    @comments            = @dataset_description.comments.find(:all, :conditions => {:record_id => record_id})
    
    # Need to do some grouping based on if comment is a response to other comment or not
    # Let's divide all comments into two kinds: Threads and Responses
    
    @threads = @comments.find_all{|comment|!comment.parent_comment}
    @responses = @comments.find_all{|comment|comment.parent_comment}
    @responses = @responses.group_by(&:parent_comment)
    
    # Rebuild comments array with threads and responses
    @comments = []
    @threads.each do |thread|
      @comments << thread
      if @responses[thread]
        @comments += @responses[thread]
      end
    end
        
    # New empty comment
    @new_comment         = Comment.new(:user => current_user, :dataset_description => @dataset_description, :record_id => record_id)
  end
end