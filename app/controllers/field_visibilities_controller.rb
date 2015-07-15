class FieldVisibilitiesController < ApplicationController

  privilege_required :edit_dataset_description

  protect_from_forgery

  def show
    dataset_description
  end

  def update
    dataset_description.attributes = params[:dataset_description]

    dataset_description.save(validate: false)
    flash[:notice] = 'DatasetDescription was successfully updated.'
    redirect_to dataset_description_field_visibilities_path(dataset_description_id: dataset_description)
  end

  private

  def dataset_description
    @dataset_description ||= DatasetDescription.find(params[:dataset_description_id])
  end
end