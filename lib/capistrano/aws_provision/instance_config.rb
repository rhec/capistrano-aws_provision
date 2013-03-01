require 'hashie'
module Capistrano
  module AwsProvision
    class BaseInstance < Hashie::Dash
      property :aws
      property :region, :required => true
      property :image_id, :default => 'ami-1136fb78' # latest released canonical ubuntu 10.04 LTS instance-backed
      property :region, :default => 'us-east'
      property :flavor_id, :default => 'm1.large'
      property :user, :default => 'ubuntu'
      property :key_name
      property :availability_zone
      property :groups, :default => ['default']
      property :tags, :default => {}
      property :block_device_mapping
      
      def create_and_wait
        server = aws.servers.create(self)
        puts "instance starting"
        server.wait_for { print '.'; server.ready? }
        puts "instance started at #{server.dns_name}, waiting for ssh"
        # ready is a lie, will not accept ssh connections right away
        no_ssh = true
        while no_ssh do
          begin
            result = server.ssh("pwd")
          rescue Errno::ECONNREFUSED
            print '.'
            sleep(1)
          else
            no_ssh = false
          end
        end
        server
      rescue Fog::Compute::AWS::Error => e
        if e.message =~ /Please retry your request by not specifying an Availability Zone or choosing (.*)./
          # we are in control of the AZ - we should parse the error message and retry 
          @available_zones = $1.split(", ")
          if @balance_az
            balance_az(@balance_az)
            retry
          elsif @randomize_az
            randomize_az
            retry
          end
        end
        raise
      end
      
      def servers_by_role
        return @servers_by_role if @servers_by_role
        @servers_by_role = {}
        aws.servers.each do |s|
          # we have assigned a tag called roles with role names for each server separated by commas
          if s.state == 'running' && s.tags.has_key?('roles')
            roles = s.tags['roles'] && s.tags['roles'].split(',')
            @servers_by_role[:any] << s
            roles.each do |r|
              @servers_by_role[r.to_sym] << s
            end
          end
        end
        @servers_by_role
      end
      
      def available_zones
        @available_zones ||= %W(a b c d e).collect { |az| "#{region}#{az}" }
      end
  
      # pick a random availability zone
      # NB: us-east-1a is not currently provisioning new instances
      def randomize_az
        @randomize_az = true
        self.availability_zone = available_zones.sample
      end
  
      # balance servers for the given role between all avaliability zones
      # TODO: This is us-east-1 specific - need to dyamically get list of available zones
      def balance_az role
        role = role.to_sym
        @balance_az = role
        az_distribution = Hash[available_zones.map { |az| [az, 0] }]
        if servers_by_role[role]
          servers_by_role[role].each do |server|
            az_distribution[server.availability_zone] += 1
          end
        end
        self.availability_zone, count = az_distribution.min_by {|k,v| v}
      end
  
      # we name servers by role and number
      # the numbers are sequential and will backfill if there are any missing
      # i.e. if web-1 exists, the next one will be web-2
      # if web-2 exists, but not web-1, the next server will be named web-1
      def server_name_for_role role
        role = role.to_sym
        if servers_by_role[role]
          existing_numbers = servers_by_role[role].collect { |s| s.tags['Name'].split("-").last.to_i }
          next_number = ((1..existing_numbers.count+1).to_a - existing_numbers).first
        else
          next_number = 1
        end
        server_name = "#{role}-#{next_number}"
      end
  
      def auto_name role
        self.tags["Name"] = server_name_for_role role
      end
      
    end
  end
end