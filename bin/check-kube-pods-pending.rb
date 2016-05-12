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
# -s SERVER - The kubernates SERVER
# -p PODS - Optional, list of specific pods to check. Defaults to all
# -t TIMEOUT - The timeout in seconds to warn on
# -r COUNT - The number of restarts to warn on
# -f FILTER - The selector filter to use to determine the pods to check
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

  option :restart_count,
         description: 'Threshold for number of restarts allowed',
         short: '-r COUNT',
         long: '--restart',
         proc: proc(&:to_i),
         default: 10

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

  def run
    pods_list = []
    failed_pods = []
    restarted_pods = []
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
      next if config[:exclude_namespace].include?(pod.metadata.namespace)
      next unless pods_list.include?(pod.metadata.name) || pods_list.include?('all')
      # Check for pending state
      if pod.status.phase == 'Pending'
        pod_stamp = Time.parse(pod.metadata.creationTimestamp)
        if (Time.now.utc - pod_stamp.utc).to_i > config[:pending_timeout]
          failed_pods << pod.metadata.name
        end
      end
      # Check restarts
      next if pod.status.containerStatuses.nil?
      pod.status.containerStatuses.each do |container|
        if container.restartCount.to_i > config[:restart_count]
          restarted_pods << container.name
        end
      end
    end

    if failed_pods.empty? && restarted_pods.empty?
      ok 'All pods are reporting as ready'
    elsif failed_pods.empty?
      critical "Pods exceeded restart threshold: #{restarted_pods.join(' ')}"
    elsif restarted_pods.empty?
      critical "Pods exceeded pending threshold: #{failed_pods.join(' ')}"
    else
      critical "Pod restart and pending thresholds exceeded, pending: #{failed_pods.join(' ')} restarting: #{restarted_pods.join(' ')}"
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
