require File.join(File.dirname(__FILE__), '..', 'spec_helper')

describe DelegatesAttributesTo, 'deprecated #delegates_attributes_to' do

  it "should call #delegate_attributes with :to => profile" do
    UserDeprecated.expects(:delegate_attributes).with(:to => :profile)
    UserDeprecated.delegates_attributes_to :profile
  end
  
  it "should call #delegate_attributes with :to => contact" do
    UserDeprecated.expects(:delegate_attributes).with(:to => :contact)
    UserDeprecated.delegates_attributes_to :contact
  end
end