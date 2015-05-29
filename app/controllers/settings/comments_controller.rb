module Settings
  class CommentsController < ApplicationController
    before_filter :login_required
    privilege_required :moderate_comments

    include CommentsHelper

    def index
      @comments = Comment.find_include_suspended
    end

    def edit
      @comment = Comment.find_include_suspended(:id=>params[:id]).first
    end

    def update
      @comment = Comment.find_include_suspended(:id=>params[:id]).first

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
