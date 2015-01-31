# -*- encoding : utf-8 -*-
class EtlConfiguration < ActiveRecord::Base
  serialize :download_path, Array
  serialize :last_run_report

  STATUS_ENUM = [:ready, :in_progress, :done, :failed]

  def status
    attr = read_attribute(:status)
    if attr.respond_to?(:to_sym)
      read_attribute(:status).try(:to_sym)
    else
      attr
    end
  end

  validates :name, presence: true, uniqueness: true
  validates_inclusion_of :status, in: STATUS_ENUM, if: lambda { |o| o.status.present? }

  def valid_for_parsing?(settings)
    if name == 'donations_parser' && settings.present?
      [2007, 2008, 2009, 2010, 2011, 2012, 2013].include?(settings.fetch(:year, 0).to_i)
    else
      false
    end
  end

  def done?
    status == STATUS_ENUM[2]
  end

  def self.parsers
    where(parser: true)
  end

  # reports

  VVO_REPORT_SCHEMA =    {download_bulletins: nil, download_bulletin: {}, download_procurement: {not_acceptable: {}, empty_suppliers: {}, processed: {}, missed: {}}}

  VVO_V2_REPORT_SCHEMA = {download_bulletins: nil, download_bulletin: {}, download_procurement_notice: {not_acceptable: {}, empty_suppliers: {}, processed: {}, missed: {}}, download_procurement_performance: {not_acceptable: {}, empty_suppliers: {}, processed: {}, missed: {}}}
  VVO_V2_KEYS_BY_TYPES = {notice: :download_procurement_notice, performance: :download_procurement_performance}

  def clear_report!
    self.last_run_report = {}
    case name
      when 'vvo_extraction'
        self.last_run_report = VVO_REPORT_SCHEMA
      when 'vvo_extraction_v2'
        self.last_run_report = VVO_V2_REPORT_SCHEMA
      else
    end
    save
  end

  def update_report!(key, attributes)
    self.last_run_report[key] = attributes
    save
  end

end
