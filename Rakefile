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
  require 'fileutils'
  require 'tmpdir'
  sh 'podman login docker.io'
  dir = Dir.mktmpdir
  begin
    sh "git clone --depth 1 https://github.com/opennetadmin/ona #{dir}"
    sh "podman build --build-arg UBUNTU_VERSION=24.04 -t ona-dev:latest #{dir}"
  ensure
    FileUtils.remove_entry dir
  end
end

desc 'Publish ONA development container to ghcr.io'
task publish_onadev_container_to_ghcr: :build_onadev_container do
  sh 'podman login ghcr.io'
  sh 'podman image push localhost/ona-dev:latest docker://ghcr.io/gsi-hpc/ona-dev:latest'
end

RSpec::Core::RakeTask.new(:integration) do |task|
  task.pattern = 'integration/**{,/*/**}/*_spec.rb'
end
