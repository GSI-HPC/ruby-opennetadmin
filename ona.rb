#!/usr/bin/env ruby
#
# This is a Ruby replacement for dcm.pl
#

require 'highline/import'
require 'ona'
require 'optparse'


#### Commandline processing

options = { :debug => 0, :params => { } }

optparse = OptionParser.new do |opts|
  opts.banner = "Usage: ona_batch_load [options] csv_file"
  
  opts.on("-l", "--login USER", "Username for DB connection") do |v|
    options[:username] = v
  end
  
  opts.on("-p", "--password PASS", "Password for DB connection") do |v|
    options[:password] = v
  end
  
  opts.on('-L', '--list', 'list available modules') do
    options[:module] = 'get_module_list'
  end
  
  opts.on('-r', '--run MODULE', 'run specified module') do |v|
    options[:module] = v
  end
  
  opts.on("-t", "--test", "Debug dry-run mode") do |v|
    options[:debug] += 1
  end
  
end.parse!

# turn key1=value1 key2=value2 ... cmdline args into a Ruby hash:
options[:params] = ARGV.inject({}){ |h,e| (k,v) = e.split('='); h[k] = v;h  }

puts options.inspect if options[:debug] > 0

# Time to ask for a password unless given on the cmdline:
if options[:username] and not options[:password]
  options[:password] = ask("Password for #{options[:username]}:") do |q|
    q.echo = "*"
  end
end

ona = ONA.new(options[:username], options[:password])

puts ona.query(options[:module], options[:params])
