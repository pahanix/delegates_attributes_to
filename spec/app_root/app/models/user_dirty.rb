class UserDirty < ActiveRecord::Base
  set_table_name 'users'
  
  belongs_to :contact
  delegates_attributes_to :contact
end