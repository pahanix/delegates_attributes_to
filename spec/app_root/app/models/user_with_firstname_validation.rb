class UserWithFirstnameValidation < ActiveRecord::Base
  set_table_name 'users'
  
  belongs_to :contact
  delegate_attributes :to => :contact
  validates_presence_of :firstname
end