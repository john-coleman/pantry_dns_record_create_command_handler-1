require 'wonga/daemon/win_rm_runner'
require 'wonga/daemon/aws_resource'
require 'resolv'

module Wonga
  module Daemon
    class DnsRecordCreateCommandHandler
      def initialize(ad_username, ad_password, publisher, logger, config)
        @ad_username = ad_username
        @ad_password = ad_password
        @publisher = publisher
        @logger = logger
        @config = config
      end

      def handle_message(message)
        ec2_instance = AWSResource.new.find_server_by_id message["instance_id"]
        domain = message["domain"]
        private_ip = ec2_instance.private_ip_address
        name_server = get_name_server(@config['daemon']['name_server'],domain)
        @logger.info "Name Server located: #{name_server}"
        dns_record_hash = create_a_record(domain, name_server, message["instance_name"], private_ip, @ad_username, @ad_password)
        @logger.debug "DNS Create WinRM command returned with #{dns_record_hash.inspect}"
        @publisher.publish(message)
      end

      def get_name_server(name_server, domain)
        if name_server.nil? || name_server.empty?
          resolver = Resolv::DNS.new()
          resolver.getresource(domain, Resolv::DNS::Resource::IN::NS).name
        else
          name_server
        end
      end

      def create_a_record(domain, name_server, hostname, private_ip, ad_username, ad_password)
        runner = WinRMRunner.new
        @logger.info "Connecting to Name Server over WinRM"
        runner.add_host(name_server, ad_username, ad_password)
        command = "dnscmd #{name_server} /RecordAdd #{domain} #{hostname} /CreatePTR A #{private_ip}"
        @logger.info "Executing: #{command}"
        runner.run_commands command 
      end

    end
  end
end

