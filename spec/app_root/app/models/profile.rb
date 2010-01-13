class Profile < ActiveRecord::Base  
  belongs_to :user
  delegates_attributes_to :user
end
