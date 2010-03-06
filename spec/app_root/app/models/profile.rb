class Profile < ActiveRecord::Base  
  belongs_to :user
  delegate_attributes :to => :user
end
