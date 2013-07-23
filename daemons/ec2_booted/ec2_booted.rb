require 'aws-sdk'
require 'yaml'
require 'json'
require 'timeout'
require 'rest_client'
require_relative '../common/config'
module Daemons
  class EC2Booted

    def initialize
      @config = Daemons::Config.instance
    end

    def update_instance_booted_status(url,msg_json,api_key,timeout)
      # Try to update Pantry
      request_url = "#{url}/aws/ec2_instances/#{msg_json["request_id"].to_s}"
      update = ({:booted=>true,:instance_id=>msg_json["instance_id"]}).to_json
      puts "#{update}"
      Timeout::timeout(timeout){
        RestClient.put request_url, update, {:content_type => :json, :'x-auth-token' => api_key }
      }
    end

    def handle_message(message)
      url = @config["pantry"]["url"]
      msg_json = JSON.parse(message["Message"])
      update_instance_booted_status(url,msg_json,@config["pantry"]["api_key"],@config["pantry"]["request_timeout"])
    end

  end
end

