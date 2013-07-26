require_relative '../common/win_rm_runner'
require_relative '../common/aws_resource'
require_relative '../common/publisher'

module Daemons
  class DnsCreateRecordCommandHandler
    def initialize(publisher = Publisher.new)
      @publisher = publisher
    end

    def handle_message(message)
      ec2_instance = AWSResource.new.find_server_by_id message["instance_id"]
      hostname = message["instance_name"]
      domain = message["domain"]
      machine_address = ec2_instance.private_dns_name || ec2_instance.private_ip_address
      
      runner = WinRMRunner.new
      runner.add_host machine_address
      
      soa_hash =  runner.run_commands "nslookup -type=soa #{domain}| find \"internet address\""
      soa_hash[:out] = soa_hash[:out].gsub(/\s+/, ' ').strip
      soa_server = /\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}/.match(soa_hash[:out])
      
      runner.run_commands "dnscmd #{soa_server} /RecordAdd #{domain} #{hostname} /CreatePTR A #{ec2_instance.private_ip_address}"
      
      @publisher.publish(message)
    end
  end
end