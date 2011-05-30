#!/usr/bin/env ruby
# Copyright (C) 2011 Vijay Brian Gupta brian.gupta@brandorr.com
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301,
# USA.
#
# v1.0 May 25, 2011 - Created a script to be run on an ec2 that registers it's
#                     own fqdn with DNS Made Easy

# Make sure the dnsmeapi.properties file is available in the location from which
# you run this

require 'rubygems'
require 'time'
require 'openssl'
require 'rest_client'
require 'json'
require 'socket'
require 'open-uri'

class CNameRecord

  def initialize(domainname)
    prophash = load_properties
    @domainname = domainname
    @apiKey = prophash["apiKey"]
    @secretKey = prophash["secretKey"]

    @requestDate = Time.now.httpdate
    @hmac = OpenSSL::HMAC.hexdigest('sha1', @secretKey, @requestDate)

    @@dme_rest_url = "http://api.dnsmadeeasy.com/V1.2/domains/"

    #intname = hostname + "-internal." + @domainname
  end

  def load_properties
    propertyfile = "dnsmeapi.properties"
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

  def get_cname_record(name)
    response = RestClient.get @@dme_rest_url + @domainname + "/records",
                            :"x-dnsme-apiKey" => @apiKey,
                            :"x-dnsme-hmac" => @hmac,
                            :"x-dnsme-requestDate" => @requestDate,
                            :accept =>:json
    nameresults = JSON.parse(response.to_str).select {
                  |x| x["name"] == name and x["type"] == "CNAME"}
    nameresults[0]
  end

  def post_cname_record(record)
    response = RestClient.post @@dme_rest_url + @domainname + "/records",
                            record.to_json,
                            :"x-dnsme-apiKey" => @apiKey,
                            :"x-dnsme-hmac" => @hmac,
                            :"x-dnsme-requestDate" => @requestDate,
                            :"accept" =>:json,
                            :"content-type" =>:json
    JSON.parse(response)
  end

  def delete_cname_record(id)
    response = RestClient.delete @@dme_rest_url + @domainname + "/records/" + id.to_s,
                            :"x-dnsme-apiKey" => @apiKey,
                            :"x-dnsme-hmac" => @hmac,
                            :"x-dnsme-requestDate" => @requestDate,
                            :accept =>:json
  end
end

@@instance_data_url = "http://169.254.169.254/latest/meta-data/"
fqdn = Socket.gethostbyname(Socket.gethostname).first
publicname = open(@@instance_data_url + 'public-hostname').read + "."
privatename = open(@@instance_data_url + 'local-hostname').read
instance_id = open(@@instance_data_url + 'instance-id').read
hostname = fqdn.split(".")[0]
domainname = fqdn.split(".")[1..-1].join(".")

cnameobject = CNameRecord.new(domainname)

myhost = cnameobject.get_cname_record(hostname)

if myhost && myhost["data"] == publicname
  #puts [hostname, domainname].join(".") + " is correct in DNS"
  exit
end

if myhost
  #puts "Record is not set correctly. Deleting the record." 
  cnameobject.delete_cname_record(myhost["id"])
end
#puts [hostname, domainname].join(".") + " doesn't exist in DNS. Adding."
dnsrecord = { "name" => hostname,
              "type" => "CNAME",
              "data" => publicname,
              "gtdLocation" => "DEFAULT",
              "ttl" => 300 }
cnameobject.post_cname_record(dnsrecord)

