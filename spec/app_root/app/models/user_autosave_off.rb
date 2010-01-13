class UserAutosaveOff < ActiveRecord::Base
  set_table_name 'users'
  
  belongs_to :contact, :autosave => false
  delegates_attributes_to :contact
  
  has_one :profile, :autosave => false
  delegates_attributes_to :profile
end