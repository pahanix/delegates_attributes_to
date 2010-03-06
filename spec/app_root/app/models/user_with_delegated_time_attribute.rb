class UserWithDelegatedTimeAttribute < ActiveRecord::Base
  set_table_name 'users'
  
  belongs_to :contact
  delegate_attribute :edited_at, :to => :contact
  
  has_one :profile, :foreign_key => 'user_id'
  delegate_attribute :changed_at, :to => :profile
  
end