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
  
  privilege_required :import_from_file
  
  ######################################################################
  # Pre-step: show load form
  def new
    @import_file = ImportFile.new
    @import_file.col_separator = ","
    @import_file.number_of_header_lines = 1
    @import_file.dataset_description_id = params[:dataset_description_id]
    
    template = CSV_TEMPLATES.find{|tpl|tpl[:id]==params[:template]}
    if template
      @template_id = template[:id]
      @import_file.col_separator = template[:col_separator]
      @import_file.number_of_header_lines = template[:header_lines]
    else
      @template_id = "default"
    end
    
    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @import_file }
      format.js
    end
  end

  ######################################################################
  # Step 1: Upload file & save information in the table
  
  def create
    @import_file = ImportFile.new(params[:import_file])

    respond_to do |format|
      if @import_file.save
        format.html { redirect_to(preview_import_file_path(@import_file)) }
      else
        format.html { render :action => "new" }
      end
    end
  end
  
  def update
    @import_file = ImportFile.find_by_id!(params[:id])
    @import_file.update_attributes(params[:import_file])
    redirect_to preview_import_file_path(@import_file)
    
  end
  
  ######################################################################
  # Step 2: Preview first X lines of file, let the user change
  # column association, show potential errors & provide link to
  # actual import.
  
  def preview
    prepare_file
    
    # Load default mapping
    @mapping = default_mapping_from_description
    
    # Guess mapping from header
    if params[:guess_mapping]
      @mapping = guess_mapping_from_headers
    end
    
    # Now we wanna do nothing but load first 20 lines of file
    @lines = @file.load_lines(20)
  end
  
  ######################################################################
  # Step 3: Do the import. Redirect it back to preview if errors 
  # occur.
  
  def import
    prepare_file
    
    if @import_file.status == 'success'
      flash[:notice] = t("import.file_already_imported")
      redirect_to preview_import_file_path(@import_file)
    end
    
    fork do
      ActiveRecord::Base.establish_connection(Rails.env + "_app")
      DatasetRecord.establish_connection Rails.env + "_data"
      @importer.import_into_dataset(@import_file,
                                    params[:column])
    end
    
    redirect_to status_import_file_path(@import_file)
  end
  
  def status
    @import_file = ImportFile.find_by_id!(params[:id])
    respond_to do |wants|
      wants.html
      wants.js
    end
  end

  def prepare_file
    @import_file = ImportFile.find_by_id!(params[:id])
    
    @importer = CsvImporter.new(@import_file.encoding)
    @importer.batch_id = @import_file.id
    if @importer.load_file(@import_file.file_path, @import_file.col_separator || ",", @import_file.number_of_header_lines)
      @file = @importer.file
    else
      @file = @importer.file
      return render :action => "errors"
    end
  end
  
  protected
  
  ######################################################################
  # Default mapping from description
  
  def default_mapping_from_description
    mapping = []
    i = 0
    @import_file.dataset_description.importable_fields.each do |fd|
      mapping[i] = fd.id
      i += 1
    end
    mapping
  end
  
  def guess_mapping_from_headers
    # We wanna skip default mapping and start over
    # trying to guess it from header.
    
    raise "Can't guess mapping if file has no headers." if (@import_file.number_of_header_lines||0)==0
    
    mapping = []
    @dataset_description = @import_file.dataset_description
    
    # Load a few first lines
    @lines = @file.load_lines(@import_file.number_of_header_lines)
    
    max_guessed_lines = 0
    @lines.each do |line|
      guessed_lines = 0
      line_mapping = []
      line.each_index do |i|
        column = line[i]
        field_description = @dataset_description.field_descriptions.where(:identifier => column.to_s.downcase.strip).first
        if field_description
          guessed_lines += 1 if field_description
          line_mapping[i] = field_description.id
        end
      end
      if guessed_lines > max_guessed_lines
        # Found new most accurate line, let's use it as mapping
        max_guessed_lines = guessed_lines
        mapping = line_mapping
      end
    end
    
    mapping
  end
  
  def init_menu
    @submenu_partial = "data_dictionary"
  end
end
