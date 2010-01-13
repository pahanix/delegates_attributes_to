class UserDefault < ActiveRecord::Base
  delegate_belongs_to :contact
  delegate_has_one :profile, :foreign_key => 'user_id'
end
