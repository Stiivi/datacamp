class RelationsController < ApplicationController

  privilege_required :edit_dataset_description

  protect_from_forgery

  def index
    dataset_description
  end

  # TODO: split to standard CRUD
  def create
    if params[:save] && dataset_description.update_attributes(params[:dataset_description])
      redirect_to dataset_description_relations_path(dataset_description_id: dataset_description), :notice => 'Relations successfully updated!'
    elsif params[:add_relation]
      dataset_description.attributes = params[:dataset_description]
      dataset_description.relations.build
      render 'index'
    elsif params[:remove_relation]
      dataset_description.attributes = params[:dataset_description]
      dataset_description.relations.delete(dataset_description.relations.last)
      render 'index'
    else
      render 'index', :notice => 'Please select all relevant fields!'
    end
  end

  private

  def init_menu
    @submenu_partial = 'data_dictionary'
  end

  def dataset_description
    @dataset_description ||= DatasetDescription.find(params[:dataset_description_id])
  end
end