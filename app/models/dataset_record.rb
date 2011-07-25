# -*- encoding : utf-8 -*-
class DatasetRecord < ActiveRecord::Base
  include ActionView::Helpers::NumberHelper
  include ActionView::Helpers::TextHelper
  
  establish_connection Rails.env + "_data"
  
  class_inheritable_accessor :dataset
  
  attr_accessor :handling_user
  
  # FIXME: add this to initialize method, use datasetore manager!
  set_primary_key :_record_id
  
  scope :active, where("record_status IS NULL OR record_status NOT IN ('suspended', 'deleted')")
  
  # def self.to_s
  #   table_name
  # end
  
  def to_param
    _record_id.to_s
  end
  
  # Converts Datacamp-specific options (NOT RAILS) into SQL.
  # Datacamp-options are same as Rails options, except you can pass
  # array of conditions (already sanitized and everything) and it will
  # join it and send as a single condition.
  def self.options_to_sql(options)
    if options[:conditions] && (options[:conditions].size > 0)
      joined_conditions = options[:conditions].collect.join(") AND (")
      options[:conditions] = "(#{joined_conditions})"
    else
      options.delete(:conditions)
    end
    construct_finder_sql(options)
  end

  # Convenience shortcut
  def self.find_by_record_id! *args
    find_by__record_id! *args
  end
  
  def self.find_by_record_id *args
    find_by__record_id *args
  end
  
  
  def quality_status_messages
    # QualityStatus.find :all, :conditions => { :table_name => @@dataset.description.identifier.to_s.sub("ds_", ""), :record_id => id }
    # TODO this is not in QualityStatus model anymore, it should be done somehow else
    []
  end
  
  def record_status
    super.blank? ? "absent" : super
  end
  
  def quality_status
    super.blank? ? "absent" : super
  end
  
  
  ########################################################################################
  # Method providing API for only those column we have marked as visible in export
  def to_hash
    fields_for_export = description.visible_field_descriptions(:export)
    # Put data into an array
    data_for_export = fields_for_export.collect{ |description| [description.identifier, self[description.identifier]] }
    # Make hash from the array (we can only turn hash into xml)
    return Hash[*data_for_export.flatten]
  end

  def visible_fields
    fields_for_export = description.visible_field_descriptions(:export)
    # Put data into an array
    return fields_for_export.collect{ |description| description.identifier }
  end
  
  def values_for_fields fields
	values = fields.collect { |field| self[field]}
  end

  def to_xml
  	hash = self.to_hash
    # Return xml
    return hash.to_xml :root => description.identifier
  end

  ########################################################################################
  # Getting different kinds of values
  
  def get_value(field_description)
    self[field_description.identifier.to_sym]
  end
  
  def get_formatted_value(field_description)
    value = get_value(field_description)
    # Apply format
    data_format = field_description.data_format
    if data_format
		# FIXME: get from system setup or localization
		# :separator =>, :delimiter =>
		# :precision => 0 get from arg

      format_arg =  field_description.data_format_argument
      format_arg = '' if format_arg.blank?
      case data_format.name
        when "number"
          value = (number_with_precision(value) rescue value)
        when "currency"
          # FIXME: Put format into argument 2
          value = number_to_currency(value, :unit => format_arg, :format => "%n %u")
        when "percentage"
          value = number_to_percentage(value)
        when "bytes"
          value = number_to_human_size(value)
        when "flag"
          if format_arg and format_arg != ""
            flag_values = format_arg.split(",")
            flag_values = flag_values.collect { |str| str.strip }
          end
        
          if not flag_values
            flag_values = [I18n.t("data_format_values.format_flag_true"), I18n.t("data_format_values.format_flag_false")]
          elsif flag_values.count == 1
            flag_values << I18n.t("data_format_values.format_flag_false")
          end
           
          if value
            value = flag_values[0]
          else
            value = flag_values[1]
          end
      end
    end
    value
  end
  
  def get_html_value(field_description, length = nil)
    value = get_formatted_value(field_description)
    value = truncate(value.to_s, :length => length, :omission => "&hellip;") if length
    
    # data_format = field_description.data_format
    # if data_format
    #   case data_format.name
    #     when "url"
    #       value = "<a href=\"#{value}\">#{value}</a>"
    #     when "email"
    #       value = "<a href=\"mailto:#{value}\">#{value}</a>"
    #   end
    # end
    return value
  end
  
  def get_truncated_html_value(field_description)
    get_html_value(field_description, 100)
  end
  
  def search_string_for_field_description(field_description)
    search_string = "column:%s %s" % [field_description.reference, get_value(field_description)]
  end
  
  ########################################################################################
  # Callbacks
  
  after_update :record_changes
  def record_changes
    changed_attributes.each do |attribute, old_value|
      next if attribute == "updated_at"
      next if old_value == self[attribute]
      change = Change.new
      change.dataset_description_id = self.dataset.description.id
      change.record_id = self.id
      change.changed_field = attribute
      change.value = old_value
      change.user_id = @handling_user.id if @handling_user
      change.save
    end
  end
  
end
