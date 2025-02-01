require 'ona'

RSpec.describe ONA do
  it "generates the correct option_string" do
    [
      [{'addptr' => false}, 'addptr=N'],
      [{'addptr' => true}, 'addptr=Y'],
    ].each do |opts, expected_optstr|
      expect(subject.option_string(opts)).to eq(expected_optstr)
    end
  end
end
