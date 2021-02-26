require 'spec_helper.rb'

describe "ManyDocumentsProxy" do
  it "should work on association" do
    answer = Answer.create(body: "42")
    json = [answer].to_json
    JSON.parse(json)[0]["body"].should == "42"
  end
end
