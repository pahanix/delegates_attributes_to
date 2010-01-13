class UserWithFirstnameValidation < ActiveRecord::Base
  set_table_name 'users'
  
  belongs_to :contact
  delegates_attributes_to :contact
  validates_presence_of :firstname
end