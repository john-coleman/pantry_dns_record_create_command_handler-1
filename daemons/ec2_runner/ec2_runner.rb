#!/usr/bin/env ruby

require 'aws-sdk'
require 'yaml'
require 'json'
require 'fog'
require 'timeout'

module Daemons
  class EC2BootInstanceHandler
    def initialize(config)
      @config = config
      @ec2 = AWS::EC2.new
    end

    def handle_message(msg_body)
      msg_json = JSON.parse(msg_body)
      existing_instance_id = machine_already_booted(msg_json["pantry_request_id"])
      if !existing_instance_id
        puts "Attempting to boot machine."
        instance_id = boot_machine(
          msg_json["pantry_request_id"],
          msg_json["instance_name"],
          msg_json["flavor"],
          msg_json["ami"],
          msg_json["team_id"],
          msg_json["subnet_id"],
          msg_json["security_group_ids"]
        )
      else
        instance_id = existing_instance_id
      end
      raise_machine_booted_event(
        msg_json["pantry_request_id"],
        instance_id        
      )
    end

    def machine_already_booted(request_id)
      machine = @ec2.instances.tagged('pantry_request_id').tagged_values("#{request_id}").first
      if !machine.nil?
        return machine.id 
      else
        return false
      end
    end

    def boot_machine(request_id, instance_name, flavor, ami, team_id, subnet_id, secgroup_ids)
      instance = @ec2.instances.create(
        image_id:         ami,
        instance_type:    flavor_id,
        count:            1,
        security_groups:  secgroup_ids,
        subnet:           subnet_id,
      )
      @ec2.client.create_tags(
        resources: instance.id,
        tags: 
        [
          { key: "Name",              value: instance_name  },
          { key: "team_id",           value: team_id        },
          { key: "pantry_request_id", value: request_id     }
        ]
      )
      puts instance.status

      previous_status = nil
      status = Timeout::timeout(300){
        while true do 
          # Valid values: ok | impaired | initializing | insufficient-data | not-applicable
          sleep(1)
          response = @ec2.client.describe_instance_status(instance_ids: [instance.id])
          instance_status = response.data[:instance_status_set][0][:instance_status]

          if instance_status != previous_status
            puts "#{instance_status}"
            previous_status = instance_status
          end
          print "."

          case instance_status
            when "initializing"
              #Continue
            when "ok"
              return instance.id
            else
              raise "Unexpected EC2 status return: #{instance_status}"
          end

        end
      }
      rescue => e
        raise e 
      end
  end
end









