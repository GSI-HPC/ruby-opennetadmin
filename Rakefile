# frozen_string_literal: true

require 'rspec/core/rake_task'
require 'rubocop/rake_task'

RuboCop::RakeTask.new do |task|
  task.requires << 'rubocop-rake'
  task.requires << 'rubocop-rspec'
end
RSpec::Core::RakeTask.new(:spec)

task default: %i[rubocop spec integration]

desc 'Build the ONA development container with podman'
task :build_onadev_container do
  unless system('podman image exists localhost/ona-dev:latest')
    `podman login docker.io`
    `git clone https://github.com/opennetadmin/ona onadev`
    `podman build --build-arg UBUNTU_VERSION=24.04 -t ona-dev:latest onadev`
    `rm -rf onadev`
  end
end

desc 'Publish ONA development container to ghcr.io'
task publish_onadev_container_to_ghcr: :build_onadev_container do
  `podman login ghcr.io`
  `podman image push localhost/ona-dev:latest docker://ghcr.io/gsi-hpc/ona-dev:latest`
end

RSpec::Core::RakeTask.new(:integration) do |task|
  task.pattern = 'integration/**{,/*/**}/*_spec.rb'
end
