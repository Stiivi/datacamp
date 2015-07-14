class DatastoreStatesController < ApplicationController

  privilege_required :edit_dataset_description

  protect_from_forgery

  def show
    @datastore_state = Dataset::DatastoreState.new(dataset_description)
  end

  def create_column_description
    column = dataset_description.dataset_schema_manager.columns.find { |column| column.name == params[:column] }

    if column.nil?
      raise ActiveRecord::RecordNotFound, "column: #{params[:column]} nod found in database table"
    end

    Dataset::DescriptionCreator.create_description_for_column(dataset_description, column)

    # FIXME: LOCALIZE: dataset.column_created_message
    flash[:notice] = "Created description for column #{column.name}"
    redirect_to dataset_description_datastore_states_path(dataset_description_id: dataset_description)
  end

  def create_table_column
    field_description = dataset_description.field_descriptions.find_by_identifier!(params[:column])
    field_description.add_dataset_column

    # FIXME: LOCALIZE: dataset.column_created_message
    flash[:notice] = "Created column #{field_description.identifier}"
    redirect_to dataset_description_datastore_states_path(dataset_description_id: dataset_description)
  end

  private

  def init_menu
    @submenu_partial = 'data_dictionary'
  end

  def dataset_description
    @dataset_description ||= DatasetDescription.find(params[:dataset_description_id])
  end
end