# -*- encoding : utf-8 -*-
# API Controller
#
# Copyright:: (C) 2009 Knowerce, s.r.o.
#
# Author:: Stefan Urbanek <stefan@knowerce.sk>
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

class ApiController < ApplicationController
  Mime::Type.register "text/yaml", :yml

  skip_before_filter :login_required
  around_filter :default_exception_handler
  before_filter :authorize_api_key

  @@api_version = "100"

  # HTTP status codes:
  #
  # 200 ok
  # 201 created
  # 304 not modified
  # 400 bad request
  # 401 unauthorized
  # 403 forbidden
  # 404 not found
  # 409 conflict
  # 500 internal server error
  # symbol status codes: http://apidock.com/rails/ActionController/Base/render

  # some notes:
  # http://code.google.com/apis/base/
  # http://code.google.com/apis/gdata/docs/2.0/reference.html
  # http://techblog.floorplanner.com/2008/03/11/putting-http-status-codes-to-use-with-rails/

  @@errors = {
    :internal_inconsistency => {
      :status => 500,
      :message => "Internal inconsistency",
      :resolution => "Contact application development team"
    },
    :unknown_request => {
      :status => 400,
      :message => "Unknown API request"
    },
    :invalid_argument => {
      :status => 400,
      :message => "Invalid argument"
    },
    :object_not_found => {
      :status => 404,
      :message => "Object not found"
    },
    :access_denied => {
      :status => 401,
      :message => "Access Denied"
    }
  }

  def version
    version = {:version => @@api_version}
    respond_to do |format|
      format.html { render :text => @@api_version }
      format.xml  { render :xml => version.to_xml }
      format.yml { render :text => @@api_version.to_yaml }
    end
  end

  def known_datacamps
    datacamps = KnownDatacamp.all
    urls = datacamps.collect { |dc| dc.url }
    respond_to do |format|
      format.text  { render :text => "#{urls.join("\n")}\n" }
      format.xml  { render :xml => datacamps.to_xml }
      format.yml { render :text => datacamps.to_yaml }
    end
  end

  def datasets
    # FIXME: take localization into account
    datasets = DatasetDescription.all

    # FIXME: Filter hidden fields
    datasets = datasets.select { |dataset|
      !dataset.is_hidden? || (dataset.is_hidden? && @current_user.has_right?(:view_hidden_datasets))
    }

    # FIXME find only those dataset that are not restricted by API
    # access level

    render :xml => datasets.to_xml
  end

  def dataset_description
    dataset = find_dataset(params[:dataset_id].to_i) || return
    track_download('popis-xml', dataset.identifier)

    render :xml => dataset.to_xml(:include => [ :field_descriptions ])
  end

  def dataset_dump
    # FIXME: Add API right: :dataet_dump_api
    dataset_description = find_dataset(params[:dataset_id].to_i)
    return unless dataset_description

    name = dataset_description.identifier
    file = Pathname(dataset_dump_path) + "#{name}-dump.csv"
    if file.exist?
      options = {:type=>"text/csv; charset=utf-8", :disposition => 'inline'}

      # FIXME: set to true on apache
      options[:x_sendfile] = false

      send_file file, options
    else
      error :object_not_found, :message => "There is no dump available for dataset #{name} (id=#{params[:dataset_id]})"
    end
  end

  def dataset_records
    dataset_description = find_dataset(params[:dataset_id].to_i) || return
    track_download('obsah-csv', dataset_description.identifier)
    name = dataset_description.identifier
    file = Pathname(dataset_dump_path) + "#{name}-dump.csv"

    if file.exist?
      send_file file, :type=>"text/csv; charset=utf-8", :x_sendfile => true, :filename => file.basename
    else
      error :object_not_found, :message => "There is no dump available for dataset #{name} (id=#{params[:dataset_id]})"
    end
  end

  def dataset_changes
    dataset = find_dataset(params[:dataset_id].to_i) || return
    track_download('zmeny-xml', dataset.identifier)
    changes = dataset.fetch_changes

    respond_to do |format|
      format.xml { render xml: changes.to_xml }
    end
  end

  def dataset_relations
    dataset = find_dataset(params[:dataset_id].to_i) || return
    track_download('relacie-xml', dataset.identifier)
    relations = dataset.fetch_relations

    respond_to do |format|
      format.xml { render xml: relations.to_xml }
    end
  end

  def render_records_in_dataset(dataset, output)
    dataset_class = dataset.dataset.dataset_record_class
    flush_counter = 0

    fields_for_export = dataset.visible_field_descriptions(:export)
    visible_fields = ["_record_id"] + fields_for_export.collect{ |field| field.identifier }

    dataset_class.find_each :batch_size => 100 do |record|
      values = record.values_for_fields(visible_fields)
      line = CSV.generate_line(values)
      output.write("#{line}\n")
      flush_counter += 1
      if flush_counter > 20
        flush_counter = 0
        output.flush
      end
    end
  end

  def record
    dataset_id = params[:dataset_id].to_i
    dataset_description = find_dataset(dataset_id) || return
    record_id = params[:record_id].to_i

    if dataset_id.nil?
      error :invalid_argument, :message => "record_id is not specified"
      return
    end

    dataset_class = dataset_description.dataset.dataset_record_class

    # FIXME: use appropriate API key based filtering
    record = dataset_class.find_by__record_id(record_id)

    if record.nil?
      error :object_not_found, :message => "Record with id #{record_id} was not found"
      return
    end

    # FIXME: do not show hidden fields
    respond_to do |format|
      format.xml  { render :xml => record.to_xml }
      format.yml { render :text => record.to_yaml }
      format.any  { render :xml => record.to_xml }
    end
  end

  def method_missing(method_id)
    method = method_id.to_s
    error "unknown_request", :message => "Unknown API method #{method}"
  end

private
  def track_download(action, dataset_identifier)
    Gabba::Gabba.new(ENV['DATANEST_GA_CODE'], 'datanest.fair-play.sk').event('api-download', action, dataset_identifier)
  rescue
    # :)
  end

  def error code, info = {}
    if params[:format] == 'xml'
      error = @@errors[code.to_sym]
      if error.nil?
        error = @@errors[:internal_inconsistency]
        message = "Unknown error code '#{code}'"
        code = :internal_inconsistency
      else
        message = info[:message].nil? ? error[:message] : info[:message]
      end

      reply = Hash.new
      reply[:code] = code
      reply[:message] = message if not message.nil?
      reply[:resolution] = error[:resolution] if not error[:resolution].nil?

      render :xml => reply.to_xml, :status => error[:status]
    else
      render 'pages/datanest_401', status: 401
    end
  end

  def dataset_dump_path
    ENV['DATANEST_DUMP_PATH'] || "#{Rails.root}/tmp"
  end

  def default_exception_handler
    yield
  rescue => exception
    error :internal_inconsistency
    logger.debug "API Exception: #{exception}"
    logger.debug exception.backtrace.join("\n")
  end

  def authorize_api_key
    @api_key = params[:api_key]

    if !@api_key or @api_key == ""
      error :access_denied, :message => "No API key provided"
      return
    end
    key = ApiKey.where("`key` = ? AND is_valid = 1", @api_key).first
    if !key
      error :access_denied, :message => "Invalid API key"
      return
    end

    user = key.user
    if !user
      error :access_denied, :message => "Unathorized key user"
      return
    end

    @current_user = user
  end

  def find_dataset(dataset_id)
    if dataset_id.nil?
      error :invalid_argument, :message => "dataset_id is not specified"
      return false
    end

    dataset = DatasetDescription.find_by_id(dataset_id)

    if dataset.nil?
      error :object_not_found, :message => "Dataset with id #{dataset_id} was not found"
      return false
    end

    if dataset.is_hidden? && !@current_user.has_right?(:view_hidden_datasets)
      error :access_denied, :message => "Insufficient privileges for dataset with id #{dataset_id}"
      return false
    end

    # TODO add checking if user can access datasets
    unless current_user.api_level > Api::RESTRICTED
      error :access_denied, :message => "Access denied for this account"
      return false
    end

    # TODO add checking if dataset can be accessed
    unless dataset.api_level > Api::RESTRICTED
      error :access_denied, :message => "Access denied for this dataset"
      return false
    end

    # TODO add checking if dataset is premium
    if dataset.api_level > current_user.api_level
      error :access_denied, :message => "Insufficient privileges"
      return false
    end

    return dataset
  end
end
