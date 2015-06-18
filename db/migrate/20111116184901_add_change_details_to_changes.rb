class AddChangeDetailsToChanges < ActiveRecord::Migration
  def self.up
    add_column :changes, :change_details, :text
    
    Change.all.each do |change|
      change.update_attribute(:change_details, [{changed_field: change.changed_field, old_value: change.value}])
    end
    
    remove_column :changes, :changed_field
    remove_column :changes, :value
  end

  def self.down
    add_column :changes, :changed_field, :string
    add_column :changes, :value, :text
    
    Change.all.each do |change|
      change.update_attributes(changed_field: change.change_details.first[:changed_field], value: change.change_details.first[:old_value])
    end
    
    remove_column :changes, :change_details
  end
end
