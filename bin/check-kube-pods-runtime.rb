#! /usr/bin/env ruby
#
#   check-kube-pods-runtime
#
# DESCRIPTION:
# => Check if pods are running longer than expected
#
# OUTPUT:
#   plain text
#
# PLATFORMS:
#   Linux
#
# DEPENDENCIES:
#   gem: sensu-plugin
#   gem: kube-client
#
# USAGE:
# -s SERVER - The kubernates SERVER
# -p PODS - REQUIRED, list of specific pods to check. Defaults to all
# -w WARN - The time in seconds to warn on
# -c CRIT - The time in seconds to flag as critical
#
# LICENSE:
#   Barry Martin <nyxcharon@gmail.com>
#   Released under the same terms as Sensu (the MIT license); see LICENSE
#   for details.
#

require 'sensu-plugin/check/cli'
require 'json'
require 'kubeclient'

class PodRuntime < Sensu::Plugin::Check::CLI
    option :api_server,
      description: 'URL to API server',
      short: '-s URL',
      long: '--api-server',
      default: ENV['KUBERNETES_MASTER']

    option :api_version,
      description: 'API version',
      short: '-v VERSION',
      long: '--api-version',
      default: 'v1'

    option :pod_list,
      description: 'List of pods to check',
      short: '-p PODS',
      long: '--pods',
      required: true

    option :warn_timeout,
      description: 'Threshold for pods to be in the pending state',
      short: '-w TIMEOUT',
      long: '--warn',
      proc: proc(&:to_i)

    option :critical_timeout,
      description: 'Threshold for Pods to be critical',
      short: '-c COUNT',
      long: '--critical',
      proc: proc(&:to_i)

    def run
      cli = PodRuntime.new
      api_server = cli.config[:api_server]
      api_version = cli.config[:api_version]

      begin
        client = Kubeclient::Client.new(api_server, api_version)
      rescue
        warning 'Unable to connect to Kubernetes API server'
      end

      pods_list = Array.new
      pods = Array.new
      warn = false
      crit = false
      message = ""
      if cli.config[:pod_filter].nil?
        pods_list = parse_list(cli.config[:pod_list])
        pods = client.get_pods
      end
      pods.each do |pod|
        if not pod.nil?
          if pods_list.include?(pod.metadata.name)
            #Check for Running state
            if pod.status.phase == 'Running'
              pod_stamp = Time.parse(pod.status.startTime)
              runtime = (Time.now.utc - pod_stamp.utc).to_i

              if !cli.config[:critical_timeout].nil? and runtime > cli.config[:critical_timeout]
                message << "#{pod.metadata.name} exceeds threshold #{cli.config[:critical_timeout]} "
                crit = true
              elsif !cli.config[:warn_timeout].nil? and runtime > cli.config[:warn_timeout]
                message << "#{pod.metadata.name} exceeds threshold #{cli.config[:warn_timeout]} "
                warn = true
              end
            end
          end
        end
      end

      if crit
        critical message
      elsif warn
        warning message
      else
        ok "All pods within threshold"
      end
    end

    def parse_list(list)
     if list and list.include?(',')
         return list.split(',')
     elsif list
         return [ list ]
     else
         return ['']
     end
   end
end
