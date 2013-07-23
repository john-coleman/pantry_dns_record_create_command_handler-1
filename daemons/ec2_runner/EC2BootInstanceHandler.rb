require 'aws-sdk'
require 'yaml'
require 'json'
require 'fog'
require 'timeout'

module Daemons
  class EC2BootInstanceHandler
    def initialize(publisher = Publisher.new)
      @config = Daemons::Config.instance 
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
      ec2 = AWS::EC2.new
      machine = ec2.instances.tagged('pantry_request_id').tagged_values("#{request_id}").first
      if !machine.nil?
        return machine.id 
      else
        return false
      end
    end

    def boot_machine(request_id, instance_name, flavor, ami, team_id, subnet_id, secgroup_ids)
      fog = Fog::Compute.new(
        provider: 'AWS',
        aws_access_key_id: @@config["aws"]["aws_access_key_id"],
        aws_secret_access_key: @@config["aws"]["aws_secret_access_key"],
        region: @@config["aws"]["region"]
      )
      ec2_inst = fog.servers.create(
        :image_id => ami,
        :flavor_id => flavor,
        :subnet_id => subnet_id,
        :security_group_ids => security_group_ids
      )
      fog.tags.create(
        :resource_id => ec2_inst.identity,
        :key => 'Name',
        :value => instance_name
      )
     fog.tags.create(
        :resource_id => ec2_inst.identity,
        :key => 'team_id',
        :value => team_id
      )
      fog.tags.create(
        :resource_id => ec2_inst.identity,
        :key => 'pantry_request_id',
        :value => pantry_request_id
      )
      puts "#{ec2_inst.state}"
      ec2_inst.wait_for { ready? }      
      previous_status = nil
      status = Timeout::timeout(300){
        while true do 
          # Valid values: ok | impaired | initializing | insufficient-data | not-applicable
          #Not a good idea to hammer AWS with requests.
          sleep(Integer(@@config["aws_request_wait"]))              
          instance_status = fog.describe_instance_status('InstanceId'=>ec2_inst.id).body["instanceStatusSet"][0]["instanceStatus"]["status"]

          if instance_status != previous_status
            puts "#{instance_status}"
            previous_status = instance_status
          end
          print "."

          case instance_status
            when "initializing"
              #Continue
            when "ok"
              return ec2_inst.id
            when "impaired"
              log_error("AWS instance returned status: impaired")
            when "insufficient-data"
              log_error("AWS instance returned status: insufficient-data")
            when "not-applicable"
              log_error("AWS instance returned status: not-applicable")
            else
              log_error("Unexpected AWS status encountered: #{instance_status}")
          end
        end
      }











