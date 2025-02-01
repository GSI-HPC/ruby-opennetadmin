# frozen_string_literal: true

#
# Copyright 2015-2024 GSI Helmholtzzentrum fuer Schwerionenforschung GmbH
#
# Authors:
#  Christopher Huhn   <C.Huhn@gsi.de>
#
# class for ONA queries, replacement for dcm.pl
#

require 'cgi'
require 'json'
require 'net/https'

# custom error class for ONA errors
class OpennetadminError < StandardError
  attr_reader :errorcode

  def initialize(message, code = -1)
    super(message)
    @errorcode = code
  end
end

# class to send queries to a ONA server's dcm.php
class ONA
  def initialize(url = nil, username = nil, password = nil, options = {})
    # read defaults from config file if available
    parse_dcm_conf('/etc/dcm.conf') if File.readable?('/etc/dcm.conf') && (options[:dcm_conf] != :ignore)
    @url      ||= url
    @username ||= username
    @password ||= password
    @options = { verify_ssl: true }.merge(options)
  end

  # read dcm.conf
  #
  # this is almost a standard ini file - but not quite
  #
  def parse_dcm_conf(filename = '/etc/dcm.conf')
    content = File.read(filename)

    # remove comments and empty lines:
    content.gsub!(/^\s*(#.*)?$/, '')
    content.squeeze!("\n")

    # split into sections
    sections = content.scan(/\[(\w+)\]([^\[]*)/m)

    options = sections.each_with_object({}) do |e, h|
      h[e[0]] = e[1].scan(/\s*(\S+)\s*=>\s*(\S+)\s*\n/).to_h
    end

    @url      ||= options['networking']['url']
    @username ||= options['networking']['login']
    @password ||= options['networking']['passwd']

    # TODO: also consider logging options, allow-http-fallback etc.

    options # return options hash
  end

  # construct the options part of the query string from the given
  #  options hash:
  def option_string(options = {})
    # options is key1=value1&key2=value2&... '&' must be URL encoded
    # we do some tricks with inject
    options.inject([]) do |a, (k, v)|
      a << case v
           when FalseClass
             "#{k}=N"
           when TrueClass, NilClass, ''
             # if options have no value we fallback to 'Y':
             "#{k}=Y"
           else
             # FIXME: If v is a filename, dcm.pl reads and passes its content
             #        I doubt this is really smart behaviour
             "#{k}=#{CGI.escape(v.to_s)}"
           end
    end.join('%26')
  end

  # send request to ONA server
  def request(uri, limit = 10)
    result = ''

    # limit the recursion depth for HTTP redirects:
    raise OpennetadminError, 'ONA server redirected too many times' if limit < 1

    begin
      Net::HTTP.start(
        uri.host, uri.port,
        use_ssl: (uri.scheme == 'https'),
        # FIXME: Don't turn off SSL verification unconditionally
        verify_mode: OpenSSL::SSL::VERIFY_NONE
      ) do |http|
        request = Net::HTTP::Get.new(uri.request_uri)
        request.basic_auth(@username, @password) if @username && @password
        response = http.request(request)
        # TODO: follow redirects (Net::HTTPRedirection)
        case response
        when Net::HTTPSuccess
          return response.body.split("\n")
        when Net::HTTPRedirection
          return request(URI.parse(response['location']), limit - 1)
        else
          # raise an error
          raise OpennetadminError.new("#{@url} responded with error #{response.code}: #{response.message}", 129)
        end
      end
    rescue Errno::EADDRNOTAVAIL, Net::HTTPClientException,
           Net::ReadTimeout, Timeout::Error => e
      raise OpennetadminError.new("Connection to #{@url} failed: " +
                                  e.to_s, 128)
    end
    result
  end

  def query(mod, options = {})
    # turn all keys into strings to avoid
    #    ie. {:format => 'bla', 'format' => 'blubb'}
    options = options.transform_keys(&:to_s)

    # Default to JSON output unless the ona_sql module is called
    options['format'] ||= mod == 'ona_sql' ? 'text' : 'json'

    # the ona_sql module has 3 variants of the sql option
    #  1) a local file
    #  2) plain sql
    #  3) a sql file on the server
    #
    # So we check if a file exists and slurp it:
    options['sql'] = File.read(options['sql']) if mod == 'ona_sql' && options['sql'] && File.readable?(options['sql'])

    # Net::HTTP.get(URI(url)) does not support HTTPS out of the box - WTF?
    uri = URI.parse("#{@url}?module=#{mod}&options=#{option_string(options)}")

    # TODO: better catch "Authorization Required"
    result = request(uri)

    if result.first =~ /^\d+\s+$/
      # first line is a pseudo return code (wurgs)
      rc = result.shift.to_i
      # For ona_sql this isn't really an error condition
      #  but the dataset count:
      raise OpennetadminError.new(result.join("\n"), rc) if rc != 0 && mod != 'ona_sql'
    end

    return result.join("\n") unless options['format'] == 'json'

    begin
      JSON.parse(result.join("\n"))
    rescue JSON::ParserError => e
      raise OpennetadminError.new(e.to_s + result.join("\n"), rc)
    end

    # return plain text:
  end

  # helper methof to convert numeric ip to dotted quad string notation:
  def self.ip_mangle(i)
    raise RangeError, "#{i} out of IPv4 address range" if i.negative? || i > (2**32) - 1

    [i].pack('N').unpack('C4').join('.')
  end
end
