#!/usr/bin/env ruby

require 'aws-sdk'
require 'yaml'
require 'json'
require 'fog'

class EC2Runner < Struct.new(:testing)
  cfile = YAML.load_file("daemon.yml")
  @@config = cfile["production"]
  AWS.config(@@config["aws"])

  def log_error(error)
    #instance_id = `wget -q -O - http://169.254.169.254/latest/meta-data/instance-id`
    sns = AWS::SNS.new()
    topic = sns.topics[@@conf["sns"]["error_arn"]]    
    topic.publish "[##ERROR##] Node <insert id> in ec2_runner: #{error}"
    puts "[##ERROR##] Node <insert id> in ec2_runner: #{error}"
  end


  def machine_already_booted(request_id)
    ec2 = AWS::EC2.new
    ec2.instances.tagged('pantry_request_id').tagged_values("#{request_id}").any?
  end


  def boot_machine(pantry_request_id, instance_name, flavor, ami, team)
    if testing
      Fog.mock!
    end
    fog = Fog::Compute.new(
      provider: 'AWS',
      aws_access_key_id: @@config["aws"]["aws_access_key_id"],
      aws_secret_access_key: @@config["aws"]["aws_secret_access_key"],
      region: @@config["aws"]["region"]
    )
    ec2_inst = fog.servers.create(:image_id => ami,:flavor_id => flavor)
    if !testing
      fog.tags.create(
        :resource_id => ec2_inst.identity,
        :key => 'Name',
        :value => instance_name
      )
     fog.tags.create(
        :resource_id => ec2_inst.identity,
        :key => 'team',
        :value => team
      )
      fog.tags.create(
        :resource_id => ec2_inst.identity,
        :key => 'pantry_request_id',
        :value => pantry_request_id
      )
      puts "#{ec2_inst.state}"
      ec2_inst.wait_for { ready? }
    end
    previous_status = nil
    while true do 
      sleep(Integer(@@config["aws_request_wait"]))
      # Valid values: ok | impaired | initializing | insufficient-data | not-applicable
      if !testing
        instance_status = fog.describe_instance_status('InstanceId'=>ec2_inst.id).body["instanceStatusSet"][0]["instanceStatus"]["status"]
      else
        instance_status = "ok"   
      end     
      if instance_status != previous_status
        puts "#{instance_status}"
        previous_status = instance_status
      end

      case instance_status
        when "initializing"
          #ignore
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
  end

  def raise_machine_booted_event(request_id)
    sns = AWS::SNS.new()
    topic = sns.topics[@@config["sns"]["topic_arn"]]
    topic.publish "#{request_id}"
  end

  def handle_message(msg_body)
    begin
      msg_json = JSON.parse(msg_body)
      if !machine_already_booted(msg_json["pantry_request_id"])
        puts "Attempting to boot machine."
        instance_id = boot_machine(
          msg_json["pantry_request_id"],
          msg_json["instance_name"],
          msg_json["flavor"],
          msg_json["ami"],
          msg_json["team"]
        )
      else
        log_error("Requested existing machine (Pantry id: #{msg_json["pantry_request_id"]}). Booting not attempted.")
      end
      if !testing
        raise_machine_booted_event(msg_json["pantry_request_id"])
      end
      return true      
    rescue Exception => e
      log_error(e)
      return false
    end
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
  ec2_runner = EC2Runner.new(false)
  ec2_runner.run()
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


