class User < ActiveRecord::Base
  has_one :profile
  delegate_attributes :to => :profile
end