# -*- encoding : utf-8 -*-
# Comments Controller
#
# Copyright:: (C) 2009 Knowerce, s.r.o.
# 
# Author:: Vojto Rinik <vojto@rinik.net>
# Date: Sep 2009
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU Lesser General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
# 
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU Lesser General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

class CommentsController < ApplicationController
  before_filter :login_required
  privilege_required :moderate_comments, :only => [:index, :edit, :update, :destroy]

  include CommentsHelper
  
  def index
    @comments = Comment.find_include_suspended
  end
  
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

  def edit
    @comment = Comment.find_include_suspended(:id=>params[:id]).first
  end
  
  def update
    
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
  
  def destroy
    @comment = Comment.find_by_id(params[:id])
    @comment.is_suspended = true
    @comment.save
    
    respond_to do |wants|
      wants.html { redirect_to comment_return_path(@comment) }
      wants.js
    end
  end
  
  #####################################################################################
  # Reporting
  
  def report
    @comment = Comment.find_by_id!(params[:id])
    @report = @comment.comment_reports.new
    @report.comment = @comment
    @report.user_id = current_user.id
    
    if request.method == :post
      @report.update_attributes params[:comment_report]
      @report.save
      redirect_to comment_return_path(@comment)
    end
  end
  
  def init_menu
    @submenu_partial = "settings"
  end
end
