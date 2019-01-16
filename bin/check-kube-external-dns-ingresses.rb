#! /usr/bin/env ruby
#
#   check-kube-external-dns-ingresses
#
# DESCRIPTION:
# => Check if ingresses with hostnames matching external-dns domains have expected DNS entries
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
#     --in-cluster                 Use ingress account authentication
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
# -f, --filter FILTER              Selector filter for ingresses to be checked
#     --ingresses INGRESSES        Optional list of specific ingresses to check.
#
# NOTES:
# => The filter used for the -f flag is in the form key=value. If multiple
#    filters need to be specfied, use a comma. ex. foo=bar,red=color
#
require 'resolv'
require 'sensu-plugins-kubernetes/cli'
require 'sensu-plugins-kubernetes/cli/namespaced'

class KubeExternalDNSIngresss < Sensu::Plugins::Kubernetes::CLI
  include Sensu::Plugins::Kubernetes::NamespacedCLI

  # We have to redefine these first two to use the extensions API group
  option :api_server,
         description: 'URL to API server',
         short: '-s URL',
         long: '--api-server',
         default: 'https://kubernetes.default/apis/extensions'

  option :api_version,
         description: 'API version',
         short: '-v VERSION',
         long: '--api-version',
         default: 'v1beta1'

  option :domain_filter,
         description: 'List of domains managed by external-dns',
         long: '--domain-filter DOMAINS',
         proc: proc { |a| a.split(',').map(&:strip).map { |i| i.sub(/\.+$/, '') } },
         required: true

  option :ingresses,
         description: 'List of ingresses to check',
         long: '--ingresses',
         proc: proc { |a| a.split(',') },
         default: []

  option :label_filter,
         description: 'Label selector for ingresses to be checked (example -- key1=value1,key2!=value2)',
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

  # Strip trailing dots
  def normalize_hostname(hostname)
    hostname.sub(/\.+$/, '')
  end

  # Returns a sorted array of external-dns hostnames set on the given ingress
  def hostnames_for_ingress(ingress)
    all_hosts = ingress.spec.rules.map { |rule| normalize_hostname(rule.host) }
    all_hosts.select { |host| config[:domain_filter].any? { |df| host.end_with?(df) } }
  end

  # Returns a sorted array of IPs for a given ingress that are exportable by external-dns
  def addresses_for_ingress(ingress)
    return [] if ingress.status.loadBalancer.nil? || ingress.status.loadBalancer.ingress.nil?
    ingress.status.loadBalancer.ingress.map(&:ip).compact.sort
  end

  def should_exclude_namespace(namespace)
    return !config[:include_namespace].include?(namespace) unless config[:include_namespace].empty?
    config[:exclude_namespace].include?(namespace)
  end

  def run
    bad_ingress_msg_map = {}

    ingresses = if config[:label_filter].nil?
                 client.get_ingresses(namespace: namespace)
               else
                 client.get_ingresses(namespace: namespace, label_selector: config[:label_filter].to_s)
               end

    ingresses.each do |s|
      next if should_exclude_namespace(s.metadata.namespace)
      next unless config[:ingresses].empty? || config[:ingresses].include?(s.metadata.name)

      hostnames = hostnames_for_ingress(s)
      next if hostnames.empty?

      # NOTE: we only support IP targets at this time, and we assume hostnames are configured for a
      # service OR ingress, but never both
      addresses = addresses_for_ingress(s)
      next if addresses.empty?

      msg_parts = []
      hostnames.each do |h|
        actual_addresses = Resolv.getaddresses(h).sort
        next if addresses == actual_addresses

        extra_ips = actual_addresses - addresses
        missing_ips = addresses - actual_addresses

        msg_parts << "#{h} has extra IPs [#{extra_ips.join(', ')}]" unless extra_ips.empty?
        msg_parts << "#{h} is missing IPs [#{missing_ips.join(', ')}]" unless missing_ips.empty?
      end

      next if msg_parts.empty?
      ingress_display_name = "#{s.metadata.namespace}/#{s.metadata.name}"
      bad_ingress_msg_map.merge!(ingress_display_name => msg_parts.join(', '))
    end

    if bad_ingress_msg_map.empty?
      ok 'No inconsistencies found'
    else
      critical "The following failures were detected: #{bad_ingress_msg_map.inspect}"
    end
  rescue KubeException => e
    critical 'API error: ' << e.message
  end
end
