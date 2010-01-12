# Searches Controller
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

class SearchesController < ApplicationController
  
  before_filter do |controller|
    controller.add_javascript('datasets/search.js')
  end
  
  def new

  end

  def create
    @engine = SearchEngine.new
    @engine.delegate = self
    
    search_params = params[:search] || {}
    
    unless params[:query_string].blank?
      search_params[:query_string] = params[:query_string]
    end
    
     # Check if we're searching with query or predicates
    if !search_params[:query_string].blank?
      search = @engine.create_global_search_with_string(params[:query_string])
    elsif search_params[:predicates]
      @predicates = create_predicates_from_hash(search_params[:predicates])
      search = @engine.create_dataset_search_with_predicates(@predicates, search_params[:dataset])
    else
      return redirect_to new_search_path
    end
    
    if search
      search.session = @current_session
      search.save
	    @engine.perform_search(search)
	    
      redirect_to search_path(search)
    else
      redirect_to new_search_path
    end
  end
  
  def show
    @search = Search.find_by_id! params[:id]
    if @search.query.scope == "dataset"
      @dataset_description = DatasetDescription.find_by_identifier @search.query.object
    end
    @results = @search.results.paginate(:page => params[:page], :per_page => 10)
    params[:query_string] = @search.query_string # We wan't to display this in the form
    
    # Cache records
    # @results.group_by(&:table_name).each do |table_name, results|
    #       record_ids = results.collect(&:record_id)
    #       records = Dataset::Base.new(table_name.to_sym).dataset_record_class.find(:all, :conditions => ["id IN (?)", record_ids])
    #       records.each do |record|
    #         results.find{|r|r.record_id == record.id}.set_record_target(record)
    #       end
    #     end
  end
  
  def search_failed(type, error_message)
    # flash[:notice] = I18n.t("errors.warning", :details => error_message)
    flash_type = :notice
    flash_type = :error if [:error].include?(type)
	# FIXME: LOCALIZE: errors.search_internal_error
    flash[flash_type] = "There was problem with your search: #{error_message}"
  end
  
  protected
  
  def create_predicates_from_hash(hash)
    hash.collect do |predicate|
      SearchPredicate.create({:scope => "record", :field => predicate[:field], :operator => predicate[:operator], :argument => predicate[:value]})
    end
  end
end