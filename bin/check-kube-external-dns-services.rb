#! /usr/bin/env ruby
#
#   check-kube-external-dns-services
#
# DESCRIPTION:
# => Check if services with external-dns annotations have expected DNS entries
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
#     --in-namespace               If running in K8S, operate in running namespace
# -n NAMESPACES,                   Exclude the specified list of namespaces
#     --exclude-namespace
# -i NAMESPACES,                   Include the specified list of namespaces, an
#     --include-namespace          empty list includes all namespaces
# -f, --filter FILTER              Selector filter for services to be checked
#     --services SERVICES          Optional list of services to check.
#                                  Defaults to 'all'
#
# NOTES:
# => The filter used for the -f flag is in the form key=value. If multiple
#    filters need to be specfied, use a comma. ex. foo=bar,red=color
#
require 'resolv'
require 'sensu-plugins-kubernetes/cli'
require 'sensu-plugins-kubernetes/cli/namespaced'

class KubeExternalDNSServices < Sensu::Plugins::Kubernetes::CLI
  include Sensu::Plugins::Kubernetes::NamespacedCLI

  option :services,
         description: 'List of services to check',
         long: '--services',
         proc: proc { |a| a.split(',') },
         default: []

  option :label_filter,
         description: 'Label selector for services to be checked (example -- key1=value1,key2!=value2)',
         short: '-f FILTER',
         long: '--filter'

  option :exclude_namespace,
         description: 'Exclude the specified list of namespaces',
         short: '-n NAMESPACES',
         long: '--exclude-namespace',
         proc: proc { |a| a.split(',') },
         default: ''

  option :include_namespace,
         description: 'Include the specified list of namespaces',
         short: '-i NAMESPACES',
         long: '--include-namespace',
         proc: proc { |a| a.split(',') },
         default: ''

  HOSTNAME_ANNOTATION = 'external-dns.alpha.kubernetes.io/hostname'.freeze

  # Returns a sorted array of external-dns hostnames set on the given service
  def hostnames_for_service(service)
    return [] if service.metadata.annotations.nil? || service.metadata.annotations[HOSTNAME_ANNOTATION].nil?
    service.metadata.annotations[HOSTNAME_ANNOTATION].gsub(/\s/, '').split(',').sort
  end

  # Returns a sorted array of IPs for a given service that are exportable by external-dns
  def addresses_for_service(service)
    return [] if service.status.loadBalancer.nil? || service.status.loadBalancer.ingress.nil?
    service.status.loadBalancer.ingress.map(&:ip).compact.sort
  end

  def should_exclude_namespace(namespace)
    return !config[:include_namespace].include?(namespace) unless config[:include_namespace].empty?
    config[:exclude_namespace].include?(namespace)
  end

  def run
    bad_service_msg_map = {}

    services = if config[:label_filter].nil?
                 client.get_services(namespace: namespace)
               else
                 client.get_services(namespace: namespace, label_selector: config[:label_filter].to_s)
               end

    services.each do |s|
      next if should_exclude_namespace(s.metadata.namespace)
      next unless config[:services].empty? || config[:services].include?(s.metadata.name)

      hostnames = hostnames_for_service(s)
      next if hostnames.empty?

      addresses = addresses_for_service(s)
      next if addresses.empty?

      msg_parts = []
      hostnames.each do |h|
        actual_addresses = Resolv.getaddresses(h).sort
        next if addresses == actual_addresses

        extra_ips = actual_addresses - addresses
        missing_ips = addresses - actual_addresses

        display_hostname = h.sub(/\.$/, '')
        msg_parts << "#{display_hostname} has extra IPs [#{extra_ips.join(', ')}]" unless extra_ips.empty?
        msg_parts << "#{display_hostname} is missing IPs [#{missing_ips.join(', ')}]" unless missing_ips.empty?
      end

      next if msg_parts.empty?
      service_display_name = "#{s.metadata.namespace}/#{s.metadata.name}"
      bad_service_msg_map.merge!(service_display_name => msg_parts.join(', '))
    end

    if bad_service_msg_map.empty?
      ok 'No inconsistencies found'
    else
      critical "The following failures were detected: #{bad_service_msg_map.inspect}"
    end
  rescue KubeException => e
    critical 'API error: ' << e.message
  end
end
