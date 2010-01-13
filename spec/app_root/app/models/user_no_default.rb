class UserNoDefault < ActiveRecord::Base
  delegate_belongs_to :contact, :fullname
end