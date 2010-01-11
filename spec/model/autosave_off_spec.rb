require File.join(File.dirname(__FILE__), '..', 'spec_helper')

describe DelegateBelongsTo, 'with dirty delegations' do

  before :all do
    User.belongs_to :contact, :autosave => false
    User.delegates_attributes_to :contact
    
    User.has_one :profile, :autosave => false
    User.delegates_attributes_to :contact
  end

  it "should NOT set contact reflection autosave option to true" do
    User.reflect_on_association(:contact).options[:autosave].should be_false
  end

  it "should NOT set profile reflection autosave option to true" do
    User.reflect_on_association(:profile).options[:autosave].should be_false
  end
  
end