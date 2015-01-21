#
# class for ONA queries, replacement for dcm.pl
#

require 'json'
require "net/https"

class ONA

  def initialize(username=nil, password=nil,
                 url='https://ona.test.gsi.de/dcm.php')
    @url = url
    @username = username
    @password = password
  end

  ### this function should be in some central lib too ...
  def query (mod, options={})

    options[:format] = 'json'

    # options is key1=value1&key2=value2&... '&' must be URL encoded
    # we do some tricks with inject
    option_string = options.inject([]) { |a,e| a << "#{e[0]}=#{e[1]}" }.join('%26')

    # Net::HTTP.get(URI(url)) does not support HTTPS out of the box - WTF?

    puts "#{@url}?module=#{mod}&options=#{option_string}"

    uri = URI.parse("#{@url}?module=#{mod}&options=#{option_string}")
    #args = {include_entities: 0, include_rts: 0, screen_name: 'johndoe', count: 2, trim_user: 1} ???
    #uri.query = URI.encode_www_form(args)

    result = ""

    Net::HTTP.start(uri.host, uri.port,
      :use_ssl => (uri.scheme == 'https'),
      :verify_mode => OpenSSL::SSL::VERIFY_NONE) do |http|
      request = Net::HTTP::Get.new(uri.request_uri)
      request.basic_auth(@username, @password) if @username and @password
      response = http.request(request)
      result = response.body.split(/\n/)
    end

    # first line is a return code (wurgs)
    rc = result.shift.to_i
    if rc != 0
      # does this really mean error condition? raise error?
      STDERR.puts "ONA error code #{rc} for #{uri}"
    end

    # TODO: catch "Authorization Required"
    begin
      return JSON.parse(result.join("\n"))
    rescue JSON::ParserError => e
      # OK, so we return plain text:
      return result.join("\n")
    end

  end

end
