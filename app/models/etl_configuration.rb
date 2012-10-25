# -*- encoding : utf-8 -*-
class EtlConfiguration < ActiveRecord::Base
  serialize :download_path, Array
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
  validates_inclusion_of :status, in: STATUS_ENUM, if: lambda {|o| o.status.present?}

  def valid_for_parsing?(settings)
    if name == 'donations_parser' && settings.present?
      [2007, 2008, 2009, 2010, 2011, 2012].include?(settings.fetch(:year, 0).to_i)
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
end
