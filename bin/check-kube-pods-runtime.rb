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

require 'sensu-plugins-kubernetes'
require 'json'

class PodRuntime < Sensu::Plugin::Check::CLI

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
    cli = PodRuntime.new
    client = self.get_client(cli)

    pods_list = []
    pods = []
    warn = false
    crit = false
    message = ''

    if cli.config[:pod_filter].nil?
      pods_list = parse_list(cli.config[:pod_list])
      pods = client.get_pods
    else
      pods = client.get_pods(label_selector: cli.config[:pod_filter].to_s)
      pods_list = ['all']
    end

    pods.each do |pod|
      next if pod.nil?
      next unless pods_list.include?(pod.metadata.name) || pods_list.include?('all')
      # Check for Running state
      next unless pod.status.phase == 'Running'
      pod_stamp = Time.parse(pod.status.startTime)
      runtime = (Time.now.utc - pod_stamp.utc).to_i

      if !cli.config[:critical_timeout].nil? && runtime > cli.config[:critical_timeout]
        message << "#{pod.metadata.name} exceeds threshold #{cli.config[:critical_timeout]} "
        crit = true
      elsif !cli.config[:warn_timeout].nil? && runtime > cli.config[:warn_timeout]
        message << "#{pod.metadata.name} exceeds threshold #{cli.config[:warn_timeout]} "
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
  end

  def parse_list(list)
    return list.split(',') if list && list.include?(',')
    return [list] if list
    ['']
  end
end
