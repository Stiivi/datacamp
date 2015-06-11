module Settings
  class CommentsController < ApplicationController
    before_filter :login_required
    privilege_required :moderate_comments

    include CommentsHelper

    def index
      @comments = Comment.within_all
    end

    def edit
      @comment = Comment.within_all.find(params[:id])
    end

    def update
      @comment = Comment.within_all.find(params[:id])

      if @comment.update_attributes(params[:comment])
        redirect_to settings_comments_path
      else
        render :action => "edit"
      end
    end

    def destroy
      @comment = Comment.find_by_id(params[:id])
      @comment.is_suspended = true
      @comment.save

      respond_to do |wants|
        wants.html { redirect_to comment_return_path(@comment) }
        wants.js
      end
    end
  end
end
