#!/usr/bin/env ruby

require_relative '../common/subscriber'
require_relative '../common/config'
require_relative 'ec2_runner'

config = Daemons.config
#config.configure_aws
sqs_poller = Daemons::Subscriber.new()
publisher = Publisher.new(config['sns']['topic_arn'])
ec2 = AWS::EC2.new

case ARGV[0]
when 'run' 
  #begin
    sqs_poller.subscribe(
      config['sqs']['boot_ec2_queue'],
      Daemons::EC2Runner.new(ec2, publisher)
    )
  #rescue => e 
  #  puts "#{e}"
  #  retry
  #end
end