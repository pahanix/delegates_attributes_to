require File.join(File.dirname(__FILE__), '..', 'spec_helper')

describe DelegateBelongsTo, 'with has one delegation' do

  before :all do
    @fields = [:about, :hobby]
    User.delegate_has_one :profile
  end

  before :each do
    @user = User.new
  end  

  it 'should declare the association' do
    User.reflect_on_association(:profile).should_not be_nil
  end

  it 'creates reader methods for the columns' do
    @fields.each do |col|
      @user.should respond_to(col)
    end
  end

  it 'creates writer methods for the columns' do
    @fields.each do |col|
      @user.should respond_to("#{col}=")
    end
  end
  
  describe "reading from no contact" do
    it "should return nil as firstname" do
      @user.about.should be_nil
    end
  
    it "should return nil as lastname" do
      @user.hobby.should be_nil
    end
  end
    

  describe "reading from existing contact" do
    before :each do
      @user.build_profile
      @user.profile.about = "I'm John"
      @user.profile.hobby = "Basketball"
    end
  
    it "should read about" do
      @user.about.should == "I'm John"
    end
  
    it "should read hobby" do
      @user.hobby.should == "Basketball"
    end
  end

  describe "assigning value to delegators" do
    it "should initialize association" do
      @user.profile.should be_nil
      @user.about = "I'm John"
      @user.profile.should_not be_nil
      @user.about.should == "I'm John"
    end
    
    it "should NOT initialize association second time" do
      @user.about = "I'm John"
      profile_object_id = @user.profile.object_id
      @user.hobby = "Basketball"
      @user.profile.object_id.should == profile_object_id
      @user.about.should == "I'm John"
    end
    
    describe "#save" do
      it "should clear changed_attribute in dirty assosiations" do
        @user.about = "I'm John"
        @user.send(:changed_attributes).size.should == 1
        @user.profile.send(:changed_attributes).size.should == 1
        @user.save
        @user.send(:changed_attributes).size.should == 0
        @user.profile.send(:changed_attributes).size.should == 0
      end
    end
    
  end
end