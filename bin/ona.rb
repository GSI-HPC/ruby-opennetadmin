#!/usr/bin/env ruby
#
# This is a Ruby replacement for dcm.pl
#
# TODO: Read config items from a config file
#

require 'io/console'
require 'ona'
require 'optparse'

#### Commandline processing

options = { debug: 0, params: {}, url: 'http://localhost/opennetadmin/dcm.php' }

OptionParser.new do |opts|
  opts.banner = 'Usage: ona.rb <action> <options>'

  opts.on('-l', '--login USER', 'Username for ONA connection') do |v|
    options[:username] = v
  end

  opts.on('-p', '--password PASS', 'Password for ONA connection') do |v|
    options[:password] = v
  end

  opts.on('-u', '--url URL', 'URL to dcm.php') do |v|
    options[:url] = v
  end

  opts.on('-L', '--list', 'list available modules') do
    options[:module] = 'get_module_list'
    options[:params] = { type: 'string' }
  end

  opts.on('-r', '--run MODULE', 'run specified module') do |v|
    options[:module] = v
  end

  opts.on('-t', '--test', 'Debug dry-run mode') do
    options[:debug] += 1
  end
end.parse!

# turn key1=value1 key2=value2 ... cmdline args into a Ruby hash:
unless ARGV.empty?
  options[:params] = ARGV.each_with_object({}) do |arg, h|
    # there must be an easier way???
    a = arg.split('=')
    h[a[0]] = a[1..-1].join('=')
    h
  end
end

STDERR.puts options.inspect if options[:debug] > 0

# try to read the password from an environment variable:
options[:password] ||= ENV['ONA_PASSWORD']

# Time to ask for a password unless given on the cmdline:
if options[:username] && !(options[:password])
  STDERR.print "Password for #{options[:username]}: "
  options[:password] = STDIN.noecho(&:gets).chomp
  STDERR.puts
end

if options[:module]
# default to text output unless explictly stated otherwise:
  options[:params]['format'] ||= 'text'
else
  # fallback to --list of no module was given
  options[:module] = 'get_module_list'
  options[:params]['format'] ||= 'text'
  options[:params]['type']   ||= 'string'
end

ona = ONA.new(options[:url], options[:username], options[:password])

begin
  STDERR.puts options[:module] + ' ' + options[:params].pretty_inspect if options[:debug] > 0
  puts ona.query(options[:module], options[:params])
rescue OpennetadminError => e
  STDERR.puts "Command failed: #{e}"
  exit(e.errorcode)
end
