# frozen_string_literal: true

Gem::Specification.new do |s|
  s.name        = 'opennetadmin'
  s.version     = '0.5.4'
  s.summary     = 'Client interface to OpenNetAdmin as a replacement for dcm.pl'
  s.author      = 'Christopher Huhn'
  s.email       = 'c.huhn@gsi.de'
  s.files       = ['lib/ona.rb']
  s.executables = ['ona.rb']
  s.homepage    = 'https://git.gsi.de/debian-packages/ruby-opennetadmin'
  s.license     = 'LGPL-3.0-only'
  s.metadata    = {
    'bug_tracker_uri' => 'https://github.com/GSI-HPC/ruby-opennetadmin/issues',
    'source_code_uri' => 'https://github.com/GSI-HPC/ruby-opennetadmin',
    'rubygems_mfa_required' => 'true',
    'github_repo' => 'ssh://github.com/GSI-HPC/ruby-opennetadmin'
  }
  s.required_ruby_version = '>= 2.7'
end
