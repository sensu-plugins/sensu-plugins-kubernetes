#! /usr/bin/env ruby
#
#   check-kube-pods-pending
#
# DESCRIPTION:
# => Check if pods are stuck in a pending state or constantly restarting
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
# -n NAMESPACES,                   Exclude the specified list of namespaces
#     --exclude-namespace
# -i NAMESPACES,                   Include the specified list of namespaces, an
#     --include-namespace          empty list includes all namespaces
# -t, --timeout TIMEOUT            Threshold for pods to be in the pending state
# -f, --filter FILTER              Selector filter for pods to be checked
# -p, --pods PODS                  Optional list of pods to check.
#                                  Defaults to 'all'
#
# NOTES:
# => The filter used for the -f flag is in the form key=value. If multiple
#    filters need to be specfied, use a comma. ex. foo=bar,red=color
#
# LICENSE:
#   Barry Martin <nyxcharon@gmail.com>
#   Released under the same terms as Sensu (the MIT license); see LICENSE
#   for details.
#

require 'sensu-plugins-kubernetes/cli'

class AllPodsAreReady < Sensu::Plugins::Kubernetes::CLI
  @options = Sensu::Plugins::Kubernetes::CLI.options.dup

  option :pod_list,
         description: 'List of pods to check',
         short: '-p PODS',
         long: '--pods',
         default: 'all'

  option :pending_timeout,
         description: 'Threshold for pods to be in the pending state',
         short: '-t TIMEOUT',
         long: '--timeout',
         proc: proc(&:to_i),
         default: 300

  option :pod_filter,
         description: 'Selector filter for pods to be checked',
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

  def run
    pods_list = []
    failed_pods = []
    pods = []
    if config[:pod_filter].nil?
      pods_list = parse_list(config[:pod_list])
      pods = client.get_pods
    else
      pods = client.get_pods(label_selector: config[:pod_filter].to_s)
      if pods.empty?
        unknown 'The filter specified resulted in 0 pods'
      end
      pods_list = ['all']
    end
    pods.each do |pod|
      next if pod.nil?
      next if should_exclude_namespace(pod.metadata.namespace)
      next unless pods_list.include?(pod.metadata.name) || pods_list.include?('all')
      # Check for pending state
      next unless pod.status.phase == 'Pending'
      pod_stamp = Time.parse(pod.metadata.creationTimestamp)
      puts pod.metadata.name
      if (Time.now.utc - pod_stamp.utc).to_i > config[:pending_timeout]
        failed_pods << "#{pod.metadata.namespace}.#{pod.metadata.name}"
      end
    end
    if failed_pods.empty?
      ok 'All pods are reporting as ready'
    else
      critical "Pods exceeded pending threshold: #{failed_pods.join(' ')}"
    end
  rescue KubeException => e
    critical 'API error: ' << e.message
  end

  def parse_list(list)
    return list.split(',') if list && list.include?(',')
    return [list] if list
    ['']
  end

  def should_exclude_namespace(namespace)
    return !config[:include_namespace].include?(namespace) unless config[:include_namespace].empty?
    config[:exclude_namespace].include?(namespace)
  end
end
