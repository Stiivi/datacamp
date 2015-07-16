class DatasetInitializationsController < ApplicationController

  privilege_required :edit_dataset_description

  before_filter :load_datasets

  protect_from_forgery

  def index
  end

  def create
    result = Dataset::TableToDataset.execute(params[:dataset])

    if result.valid?
      redirect_to dataset_initializations_path
    else
      @errors = result.errors
      render :action => "index"
    end
  end

  private

  def load_datasets
    @unbound_datasets = Dataset::UnboundDatasets.new.all
  end

  def init_menu
    @submenu_partial = "data_dictionary"
  end
end