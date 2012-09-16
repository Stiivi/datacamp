class FieldDescriptionCategoriesController < ApplicationController
  before_filter :login_required
  privilege_required :edit_dataset_description
  respond_to :html

  def index
    @categories = FieldDescriptionCategory.all
    respond_with @categories
  end

  def new
    @category = FieldDescriptionCategory.new
  end

  def create
    @category = FieldDescriptionCategory.new(params[:field_description_category])
    flash[:notice] = 'Successfully created' if @category.save
    respond_with @category
  end

  def edit
    @category = FieldDescriptionCategory.find(params[:id])
  end

  def update
    @category = FieldDescriptionCategory.find(params[:id])
    flash[:notice] = 'Successfully updated' if @category.update_attributes(params[:field_description_category])
    respond_with @category, location: field_description_categories_path
  end

  def destroy
    category = FieldDescriptionCategory.find(params[:id])
    category.destroy
    redirect_to field_description_categories_path, notice: 'deleted'
  end

  private
    def init_menu
      @submenu_partial = 'data_dictionary'
    end

end
