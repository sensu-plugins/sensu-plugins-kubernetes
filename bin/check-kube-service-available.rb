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
# -l, --list SERVICES              List of services to check. Defaults to 'all'
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

  # TODO: service filter option?

  # TODO: support namespaces in service list
  #       (ie, [<ns>:]<service_name> ??)
  # TODO: also add ns support to pod lists in other scripts
  option :service_list,
         description: 'List of services to check',
         short: '-l SERVICES',
         long: '--list',
         default: nil

  option :pendingTime,
         description: 'Time (in seconds) a pod may be pending for and be valid',
         short: '-p SECONDS',
         long: '--pending',
         default: 0,
         proc: proc(&:to_i)

  def run
    service_list = parse_list(config[:service_list])
    all_services = service_list.empty?

    failed_services = []

    client.get_services.each do |service|
      service_name = service.metadata.name

      next unless all_services || service_list.include?(service_name)
      service_list.delete(service_name)

      service_ok = if service.spec.selector.nil?
                     # Selector-less services rely on manually set endpoints,
                     # so we will verify that at least one endpoint exists.
                     endpoint_available?(service)
                   else
                     # Services with selectors should have pods at the backend,
                     # so we will verify those pod(s) are running
                     # (or pending withing the time limit)
                     pod_available?(service)
                     # TODO: Should we just rely on kubernetes endpoint management as
                     # pods pass/fail their readiness checks and just check the endpoints?
                   end

      failed_services << service_name unless service_ok

      # Exit early if we've checked all the services we were explicitly asked to
      break if !all_services && service_list.empty?
    end

    unless failed_services.empty?
      critical "All services are not ready: #{failed_services.join(' ')}"
    end

    unless service_list.empty?
      critical "Some services could not be checked: #{service_list.join(' ')}"
    end

    ok 'All services are reporting as up'
  rescue KubeException => e
    critical 'API error: ' << e.message
  end

  def parse_list(list)
    return list.split(',') if list && list.include?(',')
    return [list] if list && list != 'all'
    []
  end

  def endpoint_available?(service)
    !client.get_endpoint(service.metadata.name, service.metadata.namespace).empty?
  rescue KubeException
    # TODO: log?
    false
  end

  def pod_available?(service)
    pod_available = false
    selector = service.spec.selector.to_h.map { |k, v| "#{k}=#{v}" }.join(',')
    client.get_pods(label_selector: selector).each do |pod|
      case pod.status.phase
      when 'Pending'
        next if pod.status.startTime.nil?
        if (Time.now - Time.parse(pod.status.startTime)).to_i < config[:pendingTime]
          pod_available = true
          break # out of client pod loop
        end
      when 'Running'
        pod.status.conditions.each do |condition|
          next unless condition.type == 'Ready'
          if condition.status == 'True'
            pod_available = true
            break # out of condition loop
          end
        end
        break if pod_available # out of client pod loop
      end
    end
    pod_available
  rescue KubeException
    # TODO: log?
    false
  end
end
