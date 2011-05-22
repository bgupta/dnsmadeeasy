#!/opt/local/bin/ruby
# Copyright Vijay Brian Gupta 2011 brian.gupta@brandorr.com
# License GPLv2 http://www.gnu.org/licenses/gpl-2.0.html (replace with full text)
# v0.2 May 22, 2011 - Replicated functionality of perl script http://www.dnsmadeeasy.com/enterprisedns/api.html
#
# Make sure the dnsmeapi.properties file is available in the location from which you run this

require 'time'
require 'uri'
require 'openssl'
require 'yaml'

dmepropertyfile = "dnsmeapi.properties"
requestDate = Time.now.httpdate

 def load_properties(propertyfile)
    properties = {}
    File.open(propertyfile, 'r') do |propertyfile|
      propertyfile.read.each_line do |line|
        line.strip!
        if (line[0] != ?# and line[0] != ?=)
          i = line.index('=')
          if (i)
            properties[line[0..i - 1].strip] = line[i + 1..-1].strip
          else
            properties[line] = ''
          end
        end
      end
    end
    properties
  end

prophash = load_properties dmepropertyfile
apiKey = prophash["apiKey"]
secretKey = prophash["secretKey"]

hmac = OpenSSL::HMAC.hexdigest(OpenSSL::Digest::Digest.new('sha1'), secretKey, requestDate)

apiKeyHeader = "x-dnsme-apiKey:" + apiKey;
hmacHeader = "x-dnsme-hmac:" + hmac;
requestDateHeader = "x-dnsme-requestDate:" + "\"" + requestDate + "\"";

puts `curl #{ARGV.join(" ")} --header #{apiKeyHeader} --header #{hmacHeader} --header #{requestDateHeader}`
