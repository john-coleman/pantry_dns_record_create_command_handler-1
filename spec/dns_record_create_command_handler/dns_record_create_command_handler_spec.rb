require 'spec_helper'
require_relative '../../dns_record_create_command_handler/dns_record_create_command_handler'

describe Wonga::Daemon::DnsRecordCreateCommandHandler do
  let(:config) do
    {
      'daemon' => {
        'name_server' => 'some.name.server',
        'no_name_server' => ''
      }
    }
  end
  let(:private_ip) { '10.1.1.100' }
  let(:message) do
    {
      'pantry_request_id' => 1,
      'instance_id' => 'i-f4819cb9',
      'instance_name' => 'some-hostname',
      'domain' => 'some-domain.tld',
      'private_ip' => private_ip
    }
  end
  let(:name_server) { 'resolve.for.me' }
  let(:ad_username) { 'dns_admin' }
  let(:ad_password) { 'dns_password' }

  let(:publisher) { instance_double('Wonga::Daemon::Publisher').as_null_object }
  let(:error_publisher) { instance_double('Wonga::Daemon::Publisher').as_null_object }

  subject { described_class.new(ad_username, ad_password, publisher, error_publisher, double.as_null_object, config) }

  it_behaves_like 'handler'

  describe '#handle_message' do
    let(:instance) { instance_double('AWS::EC2::Instance', private_ip_address: private_ip).as_null_object }
    let(:aws_resource) { instance_double('Wonga::Daemon::AWSResource', find_server_by_id: instance) }

    before(:each) do
      Wonga::Daemon::AWSResource.stub(:new).and_return(aws_resource)
      subject.stub(:get_name_server).and_return(name_server)
      subject.stub(:create_a_record)
    end

    it 'gets name server' do
      subject.handle_message(message)
      expect(subject).to have_received(:get_name_server).with(config['daemon']['name_server'], message['domain'])
    end

    it 'creates an A record' do
      subject.handle_message(message)
      expect(subject).to have_received(:create_a_record).with(message['domain'], name_server, message['instance_name'], private_ip, ad_username, ad_password)
    end
  end

  describe '#handle_message publishes message to error topic for terminated instance' do
    let(:instance) { instance_double('AWS::EC2::Instance', private_ip_address: private_ip, status: :terminated).as_null_object }
    let(:aws_resource) { instance_double('Wonga::Daemon::AWSResource', find_server_by_id: instance) }

    before(:each) do
      Wonga::Daemon::AWSResource.stub(:new).and_return(aws_resource)
      subject.stub(:get_name_server).and_return(name_server)
      subject.stub(:create_a_record)
    end

    it 'does not get name server' do
      subject.handle_message(message)
      expect(subject).to_not have_received(:get_name_server)
    end

    it 'does not create an A record' do
      subject.handle_message(message)
      expect(subject).to_not have_received(:create_a_record)
    end

    it 'publishes message to error topic' do
      subject.handle_message(message)
      expect(error_publisher).to have_received(:publish).with(message)
    end

    it 'does not publish message to topic' do
      subject.handle_message(message)
      expect(publisher).to_not have_received(:publish)
    end
  end

  describe '#get_name_server' do
    let(:resolver) { instance_double('Resolv::DNS').as_null_object }
    let(:name_server_resource) { instance_double('Resolv::DNS::Resource::IN::A', address: name_server).as_null_object }

    before(:each) do
      Resolv::DNS::Resource::IN::A.stub(:new)
      Resolv::DNS.stub(:new).and_return(resolver)
      resolver.stub(:getresource).and_return(name_server_resource)
    end

    context 'name_server specified in config' do
      it 'returns the specified name server' do
        expect(subject.get_name_server(config['daemon']['name_server'], message['domain'])).to be_eql(config['daemon']['name_server'])
      end
    end
    context 'name_server not specified in config' do
      it "discovers the domain's name server" do
        expect(subject.get_name_server(config['daemon']['no_name_server'], message['domain'])).to be_eql(name_server)
        expect(resolver).to have_received(:getresource).with(message['domain'], Resolv::DNS::Resource::IN::A)
      end
    end
  end

  describe '#create_a_record' do
    let(:win_rm_runner) { instance_double('Wonga::Daemon::WinRMRunner').as_null_object }

    before(:each) do
      Wonga::Daemon::WinRMRunner.stub(:new).and_return(win_rm_runner)
    end

    it "connects to the domain's name server over WinRM" do
      subject.create_a_record(message['domain'], name_server, message['instance_name'], private_ip, ad_username, ad_password)
      expect(win_rm_runner).to have_received(:add_host).with(name_server, ad_username, ad_password)
    end

    it 'executes dns commands' do
      subject.create_a_record(message['domain'], name_server, message['instance_name'], private_ip, ad_username, ad_password)
      expect(win_rm_runner).to have_received(:run_commands).with("dnscmd #{name_server} /RecordAdd #{message['domain']} #{message['instance_name']} /CreatePTR A #{private_ip}")
    end
  end
  describe 'check_ip' do
    it 'returns an IP' do
      subject.check_ip('www.ruby-lang.org').should =~ /^(?:[0-9]{1,3}\.){3}[0-9]{1,3}$/
    end
    it 'returns nil if the name does not exists' do
      subject.check_ip('www11111111111.ruby-lang.org').should be_nil
    end
  end
end
