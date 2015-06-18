# -*- encoding : utf-8 -*-
# Assets Controller
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


class AssetsController < ApplicationController
  ######################################################################
  # Pre-step: show load form
  
  def new
    @asset = Asset.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @asset }
    end
  end

  ######################################################################
  # Step 1: Upload file & save information in the table
  
  def create
    @asset = Asset.new(params[:asset])

    respond_to do |format|
      if @asset.save
        format.html { redirect_to(preview_asset_path(@asset)) }
      else
        format.html { render :action => "new" }
      end
    end
  end
  
  ######################################################################
  # Step 2: Preview first X lines of file, let the user change
  # column association, show potential errors & provide link to
  # actual import.
  
  def preview
    prepare_file
    
    # Now we wanna do nothing but load first 20 lines of file
    @lines = @file.load_lines(20)
  end
  
  ######################################################################
  # Step 3: Do the import. Redirect it back to preview if errors 
  # occur.
  
  def import
    prepare_file
    
    if @asset.imported
      flash[:notice] = t("import.file_already_imported")
      redirect_to preview_asset_path(@asset)
    end
    
    @count = @importer.import_into_dataset(@asset.dataset_description.dataset,
                                  params[:column])
      
    # Set asset as imported
    @asset.imported = true
    @asset.save
  end
  
  def prepare_file
    @asset = Asset.find(params[:id])
    
    @importer = CsvImporter.new
    if @importer.load_file(@asset.file_path, @asset.col_separator || ",", @asset.contains_header)
      @file = @importer.file
    else
      @file = @importer.file
      return render :action => "errors"
    end
  end
  
  private
  
  def init_menu
    @submenu_partial = "data_dictionary"
  end
end
