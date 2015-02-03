#
# class for ONA queries, replacement for dcm.pl
#

require 'json'
require "net/https"

class ONA

  def initialize(url='http://localhost/ona/dcm.php', username=nil, password=nil)
    @url = url
    @username = username
    @password = password
  end

  ### this function should be in some central lib too ...
  def query (mod, options={})

    # JSON output is a GSI specific addition atm.
    #  therefore we don't default to it here
    #options[:format] ||= 'json'

    # options is key1=value1&key2=value2&... '&' must be URL encoded
    # we do some tricks with inject
    option_string = options.inject([]) do |a,e|
      a << "#{e[0]}=#{URI.encode(e[1].to_s)}"
    end.join('%26')

    # Net::HTTP.get(URI(url)) does not support HTTPS out of the box - WTF?
    uri = URI.parse("#{@url}?module=#{mod}&options=#{option_string}")

    result = ""

    begin
      Net::HTTP.start(uri.host, uri.port,
        :use_ssl => (uri.scheme == 'https'),
        # FIXME: Don't turn off SSL verification unconditionally
        :verify_mode => OpenSSL::SSL::VERIFY_NONE) do |http|
        request = Net::HTTP::Get.new(uri.request_uri)
        request.basic_auth(@username, @password) if @username and @password
        response = http.request(request)
        response.value # raise an error unless Net::HTTPSuccess
        result = response.body.split(/\n/)
      end
    rescue Net::HTTPServerException => e
      raise "Connection failed: " + e.to_s
    end

    # first line is a pseudo return code (wurgs)
    rc = result.shift.to_i
    if rc != 0
      # does this really mean error condition? raise error?
      raise "ONA error code #{rc} for #{uri}:\n#{result.join("\n")}"
    end

    # TODO: better catch "Authorization Required"
    begin
      return JSON.parse(result.join("\n"))
    rescue JSON::ParserError => e
      # OK, so we return plain text:
      return result.join("\n")
    end
  end

  # helper methof to convert numeric ip to dotted quad string notation:
  def self.ip_mangle (i)
    return [i].pack('N').unpack('C4').join('.')
  end

end
