class UserDeprecated < ActiveRecord::Base
  set_table_name 'users'
  
  belongs_to :contact
  has_one :profile
end