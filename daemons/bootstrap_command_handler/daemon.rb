#!/usr/bin/env ruby
require 'rubygems'
require 'daemons'
require_relative '../common/subscriber'
require_relative '../common/config'
require_relative 'bootstrap_command_handler'

config = Daemons::Config.initialize(File.join(File.dirname(__FILE__),"daemon.yml"))
daemon_config = {
  :backtrace => config['daemon']['backtrace'],
  :dir_mode => config['daemon']['dir_mode'].to_sym,
  :dir => "#{config['daemon']['dir']}",
  :monitor => config['daemon']['monitor']
}
Daemons.run_proc(config['daemon']['app_name']) {
#Daemons.run_proc(config['daemon']['app_name'], daemon_config) {
  begin
    Daemons::Subscriber.new.subscribe(config['sqs']['queue_name'],Daemons::BootstrapCommandHandler.new(config['sns']['topic_arn']))
  rescue => e
    puts "#{e}"
    #retry
  end
}
