require 'spec_helper'

describe RunChefClientJob do
  let(:runner) { double.as_null_object }
  let(:host) { "host" }
  let(:hosts) { [host] }
  let(:job) { FactoryGirl.create(:job) }

  context "#perform" do
    describe "for windows machine" do
      it "runs chef-client using winrm" do

      end
    end

    describe "for linux machine" do
      before(:each) do
        SshRunner.stub(:new).and_return(runner)
      end

      it "runs chef-client using ssh" do
        pending
        expect(SshRunner).to receive(:new).and_return(runner)
        RunChefClientJob.new(hosts, job.id)
      end
    end
  end
end
