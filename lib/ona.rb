#
# class for ONA queries, replacement for dcm.pl
#

require 'json'
require 'net/https'

# custom error class for ONA errors
class OpennetadminError < StandardError
  attr_reader :errorcode
  def initialize(message, code)
    super(message)
    @errorcode = code
  end
end

# class to send queries to a ONA server's dcm.php
class ONA
  def initialize(url = nil, username = nil, password = nil, options = {})
    # read defaults from config file if available
    if File.readable?('/etc/dcm.conf') && (options[:dcm_conf] != :ignore)
      parse_dcm_conf('/etc/dcm.conf')
    end
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
    content.gsub!(/^\s*(#.*)?$/, '').squeeze!("\n")

    # split into sections
    sections = content.scan(/\[(\w+)\]([^\[]*)/m)

    options = sections.each_with_object({}) do |e, h|
      h[e[0]] = e[1].scan(/\s*(\S+)\s*=>\s*(\S+)\s*\n/).to_h
    end

    @url      ||= options['networking']['url']
    @username ||= options['networking']['login']
    @password ||= options['networking']['passwd']

    # TODO: also consider logging options, allow-http-fallback etc.
  end

  # construct the options part of the query string from the given
  #  options hash:
  def option_string(options = {})
    # options is key1=value1&key2=value2&... '&' must be URL encoded
    # we do some tricks with inject
    options.inject([]) do |a, (k, v)|
      if v
        # FIXME: If v is a filename, dcm.pl reads and passes its content
        #        I doubt this is really smart behaviour
        v2 = v.to_s.gsub('=', '\=') # escape equal signs eg. in SQL queries
        a << "#{k}=#{URI.encode(v2, /[^[:alnum:]]/)}"
      else
        # if options have no value we fallback to 'Y':
        a << "#{k}=Y"
      end
    end.join('%26')
  end

  # send request to ONA server
  def request(uri)
    result = ''
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
        # raise an error unless Net::HTTPSuccess
        unless response.kind_of? Net::HTTPSuccess
          raise OpennetadminError.new("@url responded with error #{response.code}: #{response.message}", 129)
        end

        result = response.body.split(/\n/)
      end
    rescue Net::HTTPServerException => e
      raise OpennetadminError.new("Connection to #{@url} failed: " + e.to_s, 128)
    end
    result
  end

  def query(mod, options = {})
    # JSON output is a GSI specific addition atm.
    #  therefore we don't default to it here
    # options[:format] ||= 'json'

    # Net::HTTP.get(URI(url)) does not support HTTPS out of the box - WTF?
    uri = URI.parse("#{@url}?module=#{mod}&options=#{option_string(options)}")

    result = request(uri)

    # first line is a pseudo return code (wurgs)
    rc = result.shift.to_i
    if rc != 0
      # TODO: this isn't really an error condition all the time
      #  eg. for *_display methods it seems to be the dataset count
      raise OpennetadminError.new(result.join("\n"), rc)
    end

    # TODO: better catch "Authorization Required"
    begin
      return JSON.parse(result.join("\n"))
    rescue JSON::ParserError
      # OK, so we return plain text:
      return result.join("\n")
    end
  end

  # helper methof to convert numeric ip to dotted quad string notation:
  def self.ip_mangle(i)
    raise RangeError, "#{i} out of IPv4 address range" if i < 0 || i > 2**32 - 1
    [i].pack('N').unpack('C4').join('.')
  end
end
