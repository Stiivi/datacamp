class ActivitiesController < ApplicationController
  before_filter :find_model

  
  def index
    @activities = Change.includes({:dataset_description => :translations}, :user).order('changes.created_at DESC').paginate(page: params[:page], per_page: 50)
  end
  
  def show
  end

  private
  def find_model
    @activity = Change.find(params[:id]) if params[:id]
  end
end