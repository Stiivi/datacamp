# -*- encoding : utf-8 -*-
class Block < ActiveRecord::Base
  belongs_to :page
  
  has_attached_file :image, :styles => { :standard => "270x200" }
  
  #validates_attachment_presence :image
  validates_attachment_size :image, :less_than => 5.megabytes
  validates_attachment_content_type :image, :content_type => ['image/jpeg', 'image/png', 'image/gif']
  
  validates_presence_of :name
  
  def to_param
    name
  end
  
  def self.find_by_block_name(name)
    @blocks ||= Block.all
    @blocks.find_all{|block|block.name == name}.first
  end
end
