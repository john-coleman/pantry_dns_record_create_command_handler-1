#!/usr/bin/env ruby
require 'rubygems'
require 'wonga/daemon'
require_relative 'dns_record_create_command_handler/dns_record_create_command_handler'

dir_name = File.dirname(File.symlink?(__FILE__) ? File.readlink(__FILE__) : __FILE__)
Wonga::Daemon.load_config(File.expand_path(File.join(dir_name, 'config/daemon.yml')))
Wonga::Daemon.run(Wonga::Daemon::DnsRecordCreateCommandHandler.new(Wonga::Daemon.config['ad']['username'],
                                                                   Wonga::Daemon.config['ad']['password'],
                                                                   Wonga::Daemon.publisher,
                                                                   Wonga::Daemon.error_publisher,
                                                                   Wonga::Daemon.logger,
                                                                   Wonga::Daemon.config))
