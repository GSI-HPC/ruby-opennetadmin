# frozen_string_literal: true

require 'ona'

RSpec.describe ONA do
  it 'generates the correct option_string' do
    [
      [{ 'addptr' => false }, 'addptr=N'],
      [{ 'addptr' => true }, 'addptr=Y'],
      [{ 'addptr' => '' }, 'addptr=Y'],
      [{ 'addptr' => nil }, 'addptr=Y'],
      [{ 'ipaddress' => '10.10.10.10' }, 'ipaddress=10.10.10.10'],
      [{
        'addptr' => nil,
        'ipaddress' => '10.10.10.10'
      }, 'addptr=Y%26ipaddress=10.10.10.10']
    ].each do |opts, expected_optstr|
      expect(subject.option_string(opts)).to eq(expected_optstr)
    end
  end
end
