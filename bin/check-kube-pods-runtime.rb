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
# -c, --critical COUNT             Threshold for Pods to be critical
# -f, --filter FILTER              Selector filter for pods to be checked
# -p, --pods PODS                  List of pods to check
# -w, --warn TIMEOUT               Threshold for pods to be in the pending state
#
# LICENSE:
#   Barry Martin <nyxcharon@gmail.com>
#   Released under the same terms as Sensu (the MIT license); see LICENSE
#   for details.
#

require 'sensu-plugins-kubernetes/cli'

class PodRuntime < Sensu::Plugins::Kubernetes::CLI
  @options = Sensu::Plugins::Kubernetes::CLI.options.dup

  option :pod_list,
         description: 'List of pods to check',
         short: '-p PODS',
         long: '--pods',
         default: 'all'

  option :pod_filter,
         description: 'Selector filter for pods to be checked',
         short: '-f FILTER',
         long: '--filter'

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
    pods_list = []
    pods = []
    warn = false
    crit = false
    message = ''

    if config[:pod_filter].nil?
      pods_list = parse_list(config[:pod_list])
      pods = client.get_pods
    else
      pods = client.get_pods(label_selector: config[:pod_filter].to_s)
      pods_list = ['all']
    end

    pods.each do |pod|
      next if pod.nil?
      next unless pods_list.include?(pod.metadata.name) || pods_list.include?('all')
      # Check for Running state
      next unless pod.status.phase == 'Running'
      pod_stamp = Time.parse(pod.status.startTime)
      runtime = (Time.now.utc - pod_stamp.utc).to_i

      if !config[:critical_timeout].nil? && runtime > config[:critical_timeout]
        message << "#{pod.metadata.name} exceeds threshold #{config[:critical_timeout]} "
        crit = true
      elsif !config[:warn_timeout].nil? && runtime > config[:warn_timeout]
        message << "#{pod.metadata.name} exceeds threshold #{config[:warn_timeout]} "
        warn = true
      end
    end

    if crit
      critical message
    elsif warn
      warning message
    else
      ok 'All pods within threshold'
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
