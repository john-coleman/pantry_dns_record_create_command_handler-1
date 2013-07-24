#!/usr/bin/env ruby

require 'aws-sdk'
require 'json'
require 'timeout'
require_relative '../common/publisher'

module Daemons
  class EC2Runner
    def initialize(ec2, publisher)
      @ec2 = ec2
      @publisher = publisher
    end

    def handle_message(msg)
      existing_instance_id = machine_already_booted(msg["pantry_request_id"])
      if !existing_instance_id
        puts "Attempting to boot machine with id: #{msg["pantry_request_id"]}"
        instance_id = boot_machine(
          msg["pantry_request_id"],
          msg["instance_name"],
          msg["flavor"],
          msg["ami"],
          msg["team_id"],
          msg["subnet_id"],
          msg["security_group_ids"]
        )
      else
        instance_id = existing_instance_id
        puts "Machine request #{msg["pantry_request_id"]} already booted"
      end
      raise_machine_booted_event(
        msg["pantry_request_id"],
        instance_id        
      )
    end

    def raise_machine_booted_event(request_id, instance_id)
      msg = {
        request_id: request_id,
        instance_id: instance_id
      }
      @publisher.publish(msg)      
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
      begin
        instance = @ec2.instances.create(
          image_id:             ami,
          instance_type:        flavor,
          count:                1,
          security_group_ids:   [secgroup_ids],
          subnet:               subnet_id,
        )
      rescue => e 
        puts "Creating instance failed"
        return false
      end
      @ec2.client.create_tags(
        resources: [instance.id],
        tags: 
        [
          { key: "Name",              value: instance_name  },
          { key: "team_id",           value: "#{team_id}"   },
          { key: "pantry_request_id", value: "#{request_id}"}
        ]
      )
      puts "instance status: pending"
      previous_status = nil
      status = Timeout::timeout(300){
        while true do 
          sleep(3)
          begin
            #Need to wait until machine is in a vague state of existence before status
            response = @ec2.client.describe_instance_status(instance_ids: [instance.id])
            instance_status = response.data[:instance_status_set][0][:instance_status][:status]
          rescue
            sleep(1)
            retry
          end

          if instance_status != previous_status
            print "instance status: #{instance_status}"
            previous_status = instance_status
          end

          case instance_status
            when "initializing"
              print "."
            when "ok"
              return instance.id
            else
              raise "Unexpected EC2 status return: #{instance_status}"
          end
        end
      }
    end
  end
end









