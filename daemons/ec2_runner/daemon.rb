#!/usr/bin/en ruby

require_relative '../common/subscriber'
require_relative '../common/config'
require_relative 'ec2_booted'

config = Daemons::Config.instance
config.configure_aws
sqs_poller = Daemons::Subscriber.new()

case ARGV[0]
when 'run' 
  begin
    sqs_poller.subscribe(
      config['sqs']['boot_ec2_instance'],
      Daemons::EC2BootInstanceHandler.new(config)
    )
  rescue => e 
    puts "#{e}"
    retry
  end
end