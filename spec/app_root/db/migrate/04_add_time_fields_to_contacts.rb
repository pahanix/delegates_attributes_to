class AddTimeFieldsToContacts < ActiveRecord::Migration
  def self.up
    add_column :contacts, :edited_at, :date
    add_column :profiles, :changed_at, :datetime
  end
  
  def self.down
    remove_column :contacts, :edited_at
    remove_column :profiles, :changed_at
  end
end