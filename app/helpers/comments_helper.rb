# -*- encoding : utf-8 -*-
module CommentsHelper
  def comment_return_path(comment)
    if comment.record_id
      dataset_record_path(@comment.dataset_description, comment.record_id)
    else
      dataset_path(@comment.dataset_description) + "#comments"
    end
  end
end
