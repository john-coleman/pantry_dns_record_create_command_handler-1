require_relative '../common/ssh_runner'
require_relative '../common/win_rm_runner'
require_relative '../common/aws_resource'
require_relative '../common/publisher'
require_relative '../common/config'

module Daemons
  class Bootstrap
    def handle_message(message)
      ec2_instance = AWSResource.new.find_server_by_id message["instance_id"]
      windows = ec2_instance.platform == "windows"
      machine_address = ec2_instance.private_dns_name || ec2_instance.private_ip_address

      runner = windows ? WinRMRunner.new : SshRunner.new
      runner.add_host machine_address
      runner.run_commands "chef-client"

      Publisher.new.publish(Daemons.config['ec2_queue_bootstraped'], message)
    end
  end
end

