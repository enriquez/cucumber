require File.dirname(__FILE__) + '/../spec_helper'

require 'cucumber'

module Cucumber
  describe FeatureLoader do
    before do
      @out = StringIO.new
      @log = Logger.new(@out)
      @feature_loader = FeatureLoader.new
      @feature_loader.log = @log
    end
    
    it "should have English adverbs by default" do
      @feature_loader.adverbs.should == ["Given", "When", "Then", "And", "But"]
    end
    
    it "should have other adverbs if other languages are used"
    
    it "should load features and return a collection of asts" do
      pending
      @feature_loader.load_plain_text_features("example.feature")
    end
    
    it "should split the content name and line numbers from the sources"
  end
end