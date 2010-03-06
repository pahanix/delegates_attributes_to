class UserPartiallyDirty < ActiveRecord::Base
  set_table_name 'users'
  
  belongs_to :contact
  delegate_attributes :firstname, :to => :contact
end