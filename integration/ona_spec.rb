# frozen_string_literal: true

require 'ona'
require 'net/http'

# Generate new port number each time asked
class PortManager
  @next_port = 11_080

  def self.next_port
    port = @next_port
    @next_port += 1
    port
  end
end

def with_retries(max_retries = 30)
  (1..max_retries).each do
    begin
      yield
      return
    rescue StandardError
      # do nothing
    end
    sleep(0.2)
  end
  raise "max retries #{max_retries} reached, aborting"
end

def ephemeral_onadev_container
  host = 'localhost'
  port = PortManager.next_port
  container_prefix = 'onadev_'
  dcm_path = '/ona/dcm.php'
  @dcm_endpoint = "http://#{host}:#{port}#{dcm_path}"
  name = "#{container_prefix}#{port}"

  # define and start ephemeral (--rm) container
  `podman container create -p #{port}:80 --name #{name} --rm docker://ghcr.io/gsi-hpc/ona-dev:latest`
  `podman container start #{name}`

  # wait for webserver
  with_retries do
    res = Net::HTTP.start(host, port).get(dcm_path)
    raise unless res.is_a?(Net::HTTPSuccess)
  end

  yield
ensure
  `podman container kill #{name}`
end

describe ONA do
  subject(:ona) { described_class.new(@dcm_endpoint, 'admin', 'admin') } # rubocop:disable RSpec/InstanceVariable

  around { |ex| ephemeral_onadev_container(&ex) }

  describe 'get_module_list' do
    subject(:result) { ona.query('get_module_list', { type: 'array' }) }

    it 'returns the module list' do
      expect(result).to be_an_instance_of(Hash).and \
        include('domain_display')
    end
  end

  describe 'domain_display' do
    subject(:result) { ona.query('domain_display', { domain: 'example.com' }) }

    it { is_expected.to include('fqdn' => 'example.com') }
  end
end
