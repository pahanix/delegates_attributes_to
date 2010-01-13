class UserMixed < ActiveRecord::Base
  delegate_belongs_to :contact, :defaults, :fullname
end