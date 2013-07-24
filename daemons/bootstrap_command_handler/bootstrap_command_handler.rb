require_relative '../common/ssh_runner'
require_relative '../common/win_rm_runner'
require_relative '../common/aws_resource'
require_relative '../common/publisher'

module Daemons
  class BootstrapCommandHandler
    def initialize(publisher = Publisher.new)
      @publisher = publisher
    end

    def handle_message(message)
      return false unless valid_message?(message)
      ec2_instance = AWSResource.new.find_server_by_id message["instance_id"]
      windows = ec2_instance.platform == "windows"
      machine_address = ec2_instance.private_dns_name || ec2_instance.private_ip_address

      runner = windows ? WinRMRunner.new : SshRunner.new
      runner.add_host machine_address
      runner.run_commands "chef-client"

      @publisher.publish(message)
    end

    def valid_message?(message)
      if message['instance_id'].nil?
        @publisher.publish_error("Malformed message from SQS missing request_id and/or instance_id: #{message}")
        return false
      end
      unless /^i-[[:xdigit:]]{8}$/.match(message["instance_id"].to_s)
        @publisher.publish_error("Malformed message from SQS missing request_id and/or instance_id: #{message}")
        return false
      end

      true
    end
  end
end

