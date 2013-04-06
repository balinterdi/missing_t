require_relative '../spec_helper'

describe "MissingT" do
  describe "correctly finds all missing translations" do
    m = MissingT.new({ languages: ["en"], path: "spec/support/new.html.erb" })
    m.collect['spec/support/new.html.erb'].should =~ [
      "en.flights.new.new_flight", "en.flights.new.name", "en.flights.new.capacity",
      "en.flights.new.duration", "en.flights.new.from", "en.flights.new.to",
      "en.flights.new.create", "en.flights.new.back"
    ]
  end
end
