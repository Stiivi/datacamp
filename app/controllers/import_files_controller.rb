# -*- encoding : utf-8 -*-
# Imported Files Controller
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

class ImportFilesController < ApplicationController
  respond_to :html, :xml, :js
  
  privilege_required :import_from_file
  
  def index
    redirect_to new_import_file_path
  end
  
  def new
    @import_file = ImportFile.new(dataset_description_id: params[:dataset_description_id])
    respond_with(@import_file)
  end
  
  def create
    @import_file = ImportFile.new(params[:import_file])

    if @import_file.save && @import_file.attachment_csv_errors.blank?
      redirect_to preview_import_file_path(@import_file)
    else
      render :new
    end
  end
  
  def preview
    @import_file = ImportFile.find(params[:id])
    @mapping = @import_file.mapping_from_header if @import_file.has_header?
    @sample = @import_file.sample
  end
  
  def update
    @import_file = ImportFile.find(params[:id])
    if @import_file.update_attributes(params[:import_file]) && @import_file.attachment_csv_errors.blank?
      redirect_to preview_import_file_path(@import_file)
    else
      render :new
    end
  end
  
  def show
    @import_file = ImportFile.find(params[:id])
    render :new
  end
  
  def import
    @import_file = ImportFile.find(params[:id])
    if @import_file.status == 'success'
      redirect_to preview_import_file_path(@import_file), notice: t("import.file_already_imported")
    else
      @import_file.delay.import_into_dataset(params[:column], current_user)
      redirect_to state_import_file_path(@import_file)
    end
  end
  
  def state
    @import_file = ImportFile.find(params[:id])
    respond_with(@import_file)
  end
  
  def cancel
    @import_file = ImportFile.find(params[:id])
    @import_file.cancel
    redirect_to state_import_file_path(@import_file)
  end

  def delete_records
    @import_file = ImportFile.find(params[:id])
    @import_file.delete_records!
    redirect_to state_import_file_path(@import_file), notice: t("import.deleted_records")
  end
  
private
  def init_menu
    @submenu_partial = "data_dictionary"
  end
end
