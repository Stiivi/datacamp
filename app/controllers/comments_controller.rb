class CommentsController < ApplicationController
  include CommentsHelper

  before_filter :login_required

  def new
    @comment = Comment.new
    if params[:parent_comment_id]
      @parent_comment = Comment.find_by_id!(params[:parent_comment_id])
      @comment.parent_comment_id = @parent_comment.id
      @comment.dataset_description_id = @parent_comment.dataset_description_id
      @comment.record_id = @parent_comment.record_id
    end
  end

  def create
    comment = Comment.new(params[:comment].merge(user: current_user))
    if comment.save
      redirect_to comment_return_path(comment), notice: I18n.t('comments.created_notice')
    else
      redirect_to root_url, notice: I18n.t('comments.created_error_notice')
    end
  end

  def rate
    @comment = Comment.find_by_id!(params[:id])
    rating = @comment.comment_ratings.find_by_user_id(current_user.id)
    unless rating
      rating = CommentRating.new
      rating.user_id = current_user.id
      rating.comment = @comment
    end
    rating.value = params[:rating] == "positive" ? 1 : (params[:rating] == "negative" ? -1 : 0)
    rating.save

    respond_to do |wants|
      wants.js
      wants.html { redirect_to comment_return_path(@comment) }
    end
  end


  #####################################################################################
  # Reporting

  def report
    @comment = Comment.find_by_id!(params[:id])
    @report = @comment.comment_reports.new
    @report.comment = @comment
    @report.user_id = current_user.id

    if request.post?
      @report.update_attributes params[:comment_report]
      @report.save
      redirect_to comment_return_path(@comment)
    end
  end
end

