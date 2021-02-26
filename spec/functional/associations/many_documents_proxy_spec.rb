require 'spec_helper.rb'

describe "ManyDocumentsProxy" do
  it "should work on association" do
    answer = Answer.new(body: "42")
    json = [answer].to_json
    expect(JSON.parse(json)[0]["body"]).to eq("42")
  end
end
