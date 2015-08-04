class ActivitiesController < ApplicationController
  def index
    @activities = Change.includes({:dataset_description => :translations}, :user).order('id DESC').paginate(page: params[:page], per_page: 50)
  end
  
  def show
    @activity = Change.find(params[:id])
  end
end