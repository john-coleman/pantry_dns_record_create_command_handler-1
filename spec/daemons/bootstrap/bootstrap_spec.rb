require 'spec_helper'
require "#{Rails.root}/daemons/bootstrap/bootstrap"

shared_examples "bootstrap with runner" do
  it "runs chef_client command" do
    subject.handle_message message
    expect(runner).to have_received(:run_commands).with('chef-client')
  end

  it "connects to machine" do
    subject.handle_message message
    expect(runner).to have_received(:add_host).with(address)
  end

  it "publishes success message" do
    subject.handle_message message
    expect(publisher).to have_received(:publish).with(message)
  end
end

describe Daemons::Bootstrap do
  let(:message) { { 'instance_id' => "i-11111111" } }
  let(:publisher) { instance_double('Publisher').as_null_object }
  subject(:bootstrap) { Daemons::Bootstrap.new(publisher) }

  context "#handle_message" do
    let(:instance) { double }
    let(:address) { 'some.address' }

    before(:each) do
      AWSResource.stub_chain(:new, :find_server_by_id).and_return(instance)
      instance.stub(:private_dns_name).and_return(address)
    end

    context "for linux machine" do
      let(:runner) { instance_double('SshRunner').as_null_object }

      before(:each) do
        instance.stub(:platform)
        SshRunner.stub(:new).and_return(runner)
      end

      it_should_behave_like "bootstrap with runner"
    end

    context "for windows machine" do
      let(:runner) { instance_double('WinRMRunner').as_null_object }

      before(:each) do
        instance.stub(:platform).and_return('windows')
        WinRMRunner.stub(:new).and_return(runner)
      end

      it_should_behave_like "bootstrap with runner"
    end
  end

  context "#valid_message?" do
    subject { bootstrap.valid_message?(message) }

    it { should be_true }

    context "when message doesn't have instance_id" do
      let(:message) { {} }

      it { should be_false }

      it "notifies using Publisher" do
        subject
        expect(publisher).to have_received(:publish_error)
      end
    end

    context "when instance_id has invalid format" do
      let(:message) { { "instance_id" => 1 } }

      it { should be_false }

      it "notifies using Publisher" do
        subject
        expect(publisher).to have_received(:publish_error)
      end
    end
  end
end
