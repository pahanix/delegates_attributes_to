class User < ActiveRecord::Base
  has_one :profile
  delegates_attributes_to :profile
end