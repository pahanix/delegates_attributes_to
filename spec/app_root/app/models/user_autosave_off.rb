class UserAutosaveOff < ActiveRecord::Base
  set_table_name 'users'
  
  belongs_to :contact, :autosave => false
  delegate_attributes :to => :contact
  
  has_one :profile, :autosave => false
  delegate_attributes :to => :profile
end