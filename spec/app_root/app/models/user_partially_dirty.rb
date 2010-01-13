class UserPartiallyDirty < ActiveRecord::Base
  set_table_name 'users'
  
  belongs_to :contact
  delegates_attributes_to :contact, :firstname
end