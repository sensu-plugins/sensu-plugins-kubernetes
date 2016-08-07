#! /usr/bin/env ruby
#
#   check-kube-pods-service-available
#
# DESCRIPTION:
# => Check if your kube services are up and ready
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
# -s, --api-server URL             URL to API server
# -v, --api-version VERSION        API version. Defaults to 'v1'
#     --in-cluster                 Use service account authentication
#     --ca-file CA-FILE            CA file to verify API server cert
#     --cert CERT-FILE             Client cert to present
#     --key KEY-FILE               Client key for the client cert
# -u, --user USER                  User with access to API
#     --password PASSWORD          If user is passed, also pass a password
#     --token TOKEN                Bearer token for authorization
#     --token-file TOKEN-FILE      File containing bearer token for authorization
# -l, --list SERVICES              List of services to check (required)
# -p, --pending SECONDS            Time (in seconds) a pod may be pending for and be valid
#
# NOTES:
#
# LICENSE:
#   Barry Martin <nyxcharon@gmail.com>
#   Released under the same terms as Sensu (the MIT license); see LICENSE
#   for details.
#

require 'sensu-plugins-kubernetes/cli'
require 'time'

class AllServicesUp < Sensu::Plugins::Kubernetes::CLI
  @options = Sensu::Plugins::Kubernetes::CLI.options.dup

  option :service_list,
         description: 'List of services to check',
         short: '-l SERVICES',
         long: '--list',
         required: true

  option :pendingTime,
         description: 'Time (in seconds) a pod may be pending for and be valid',
         short: '-p SECONDS',
         long: '--pending',
         default: 0,
         proc: proc(&:to_i)

  def run
    services = parse_list(config[:service_list])
    failed_services = []
    s = client.get_services
    s.each do |a|
      next unless services.include?(a.metadata.name)
      # Build the selector key so we can fetch the corresponding pod
      selector_key = []
      services.delete(a.metadata.name)
      a.spec.selector.to_h.each do |k, v|
        selector_key << "#{k}=#{v}"
      end
      # Get the pod
      pod = nil
      begin
        pod = client.get_pods(label_selector: selector_key.join(',').to_s)
      rescue
        failed_services << a.metadata.name.to_s
      end
      # Make sure our pod is running
      next if pod.nil?
      pod_available = false
      pod.each do |p|
        case p.status.phase
        when 'Pending'
          next if p.status.startTime.nil?
          if (Time.now - Time.parse(p.status.startTime)).to_i < config[:pendingTime]
            pod_available = true
            break
          end
        when 'Running'
          p.status.conditions.each do |c|
            next unless c.type == 'Ready'
            if c.status == 'True'
              pod_available = true
              break
            end
            break if pod_available
          end
        end
        failed_services << "#{p.metadata.namespace}.#{p.metadata.name}" if pod_available == false
      end
    end

    if failed_services.empty? && services.empty?
      ok 'All services are reporting as up'
    end

    if !failed_services.empty?
      critical "All services are not ready: #{failed_services.join(' ')}"
    else
      critical "Some services could not be checked: #{services.join(' ')}"
    end
  rescue KubeException => e
    critical 'API error: ' << e.message
  end

  def parse_list(list)
    return list.split(',') if list && list.include?(',')
    return [list] if list
    ['']
  end
end
