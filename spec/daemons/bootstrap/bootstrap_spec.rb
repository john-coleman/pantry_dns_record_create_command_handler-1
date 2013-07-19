require 'spec_helper'
require "#{Rails.root}/daemons/bootstrap/bootstrap"

shared_examples "bootstrap with runner" do
  let(:message) { { 'instance_id' => 1 } }
  before(:each) do
    runner.stub(:add_host)
    runner.stub(:run_commands)
  end

  it "runs chef_client command" do
    expect(runner).to receive(:run_commands).with('chef-client')
    subject.handle_message(message)
  end

  it "connects to machine" do
    expect(runner).to receive(:add_host).with(address)
    subject.handle_message(message)
  end

  it "publishes success message" do
    expect(publisher).to receive(:publish)
    subject.handle_message(message)
  end
end

describe Daemons::Bootstrap do
  context "#handle_message" do
    let(:instance) { double }
    let(:address) { 'some.address' }
    let(:publisher) { double.as_null_object }

    before(:each) do
      Publisher.stub(:new).and_return(publisher)
      AWSResource.stub_chain(:new, :find_server_by_id).and_return(instance)
      instance.stub(:private_dns_name).and_return(address)
    end

    context "for linux machine" do
      let(:runner) { instance_double('SshRunner') }

      before(:each) do
        instance.stub(:platform)
        SshRunner.stub(:new).and_return(runner)
      end

      it_should_behave_like "bootstrap with runner"
    end

    context "for windows machine" do
      let(:runner) { instance_double('WinRMRunner') }

      before(:each) do
        instance.stub(:platform).and_return('windows')
        WinRMRunner.stub(:new).and_return(runner)
      end

      it_should_behave_like "bootstrap with runner"
    end
  end
end
