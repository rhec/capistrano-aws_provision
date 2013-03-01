require "capistrano/aws_provision/version"
require "capistrano/aws_provision/instance_config"

module Capistrano
  module AwsProvision
    def aws
      return @aws if @aws
      @aws = {}
      config = YAML.load_file(fetch(:ec2_config, 'config/ec2.yml'))
      regions = config[:aws_params][:regions] || [config[:aws_params][:region]]
      regions.each do |region|
        @aws[region] = Fog::Compute.new({ 
          :provider => 'AWS',
          :region => region, 
          :aws_access_key_id => config[:aws_access_key_id], 
          :aws_secret_access_key => config[:aws_secret_access_key] 
        })
      end
      @aws
    end

    def aws_provision(instance_config)
      instance_config.create_and_wait
    end

  end
end

if Capistrano::Configuration.instance
  Capistrano::Configuration.instance.extend Capistrano::AwsProvision
end