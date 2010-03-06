class UserDirty < ActiveRecord::Base
  set_table_name 'users'
  
  belongs_to :contact
  delegate_attributes :to => :contact
end