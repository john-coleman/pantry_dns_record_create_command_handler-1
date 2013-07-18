#!/usr/bin/env ruby

require 'aws-sdk'
require 'yaml'
require 'json'
require 'fog'
require 'timeout'

module Daemons
  class Daemons::EC2Runner < Struct.new(:testing)
    cfile = YAML.load_file(File.join(File.dirname(__FILE__), "daemon.yml"))
    @@config = cfile["production"]
    AWS.config(@@config["aws"])

    #Send error details along with node id to sns error topic
    def log_error(error)
      begin
        #If node id isn't returned in reasonable time assume !ec2 node
        status = Timeout::timeout(1){
          instance_id = `wget -q -O - http://169.254.169.254/latest/meta-data/instance-id`
        }
      rescue Timeout::Error
        instance_id = "local"
      end
      if !testing
        sns = AWS::SNS.new()
        topic = sns.topics[@@config["sns"]["error_arn"]]    
        error_msg = "[##ERROR##] Node #{instance_id} in ec2_runner: #{error}"
        topic.publish error_msg
      end
      puts error_msg
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

    def boot_machine(pantry_request_id, instance_name, flavor, ami, team_id, subnet_id, security_group_ids)
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
      begin
        status = Timeout::timeout(300){
          while true do 
            # Valid values: ok | impaired | initializing | insufficient-data | not-applicable
            if !testing
               #Not a good idea to hammer AWS with requests.
              sleep(Integer(@@config["aws_request_wait"]))              
              instance_status = fog.describe_instance_status('InstanceId'=>ec2_inst.id).body["instanceStatusSet"][0]["instanceStatus"]["status"]
            else
              instance_status = 'ok'
            end

            if instance_status != previous_status
              puts "#{instance_status}"
              previous_status = instance_status
            end

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
      rescue Timeout::Error 
        log_error("Booting timed out")
      end
    end

    def raise_machine_booted_event(request_id, instance_id)
      sns = AWS::SNS.new()
      msg = {
        request_id: request_id,
        instance_id: instance_id
      }.to_json
      topic = sns.topics[@@config["sns"]["topic_arn"]]
      topic.publish msg
    end

    def invalid_json?(json_)
      JSON.parse(json_)
      return false
    rescue Exception => e
      return e
    end

    def handle_message(msg_body)
      rc = invalid_json?(msg_body)
      if rc
        log_error(rc)
        return false 
      end
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
        log_error("Requested existing machine (Pantry id: #{msg_json["pantry_request_id"]}). Booting not attempted.")
      end
      if !testing
        raise_machine_booted_event(
          msg_json["pantry_request_id"],
          instance_id
        )
      end
      return true      
    rescue Exception => e
      log_error(e)
      return false
    end

    def run
      puts "Ec2 Runner started"
      sqs = AWS::SQS.new()
      queue = sqs.queues.named(@@config["sqs"]["queue_name"])

      queue.poll do |msg|
        handle_message(msg.body)
      end
    end
  end

  case ARGV[0]
  when "run"
    ec2_runner = Daemons::EC2Runner.new(false)
    ec2_runner.run()
  end
end

=begin
{
  "pantry_request_id" : "30",
  "instance_name" : "sqs test",
  "flavor" : "t1.micro",
  "ami" : "ami-fedfd48a",
  "team" : "test team"
}
=end


