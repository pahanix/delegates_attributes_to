class UserWithDelegatedTimeAttribute < ActiveRecord::Base
  set_table_name 'users'
  
  belongs_to :contact
  delegates_attributes_to :contact, :edited_at
  
  has_one :profile, :foreign_key => 'user_id'
  delegates_attributes_to :profile, :changed_at
  
end