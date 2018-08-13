#! /usr/bin/env ruby
#
#   pod-metrics
#
# DESCRIPTION:
#   Will give pod counts from all the exposed services
#
# OUTPUT:
#   metric data
#
# PLATFORMS:
#   Linux
#
# DEPENDENCIES:
#   gem: sensu-plugin
#   gem: kube-client
#
# USAGE:
#
# NOTES:
#
# LICENSE:
#   Copyright 2016 Chris McFee <cmcfee@kent.edu>
#   Released under the same terms as Sensu (the MIT license); see LICENSE
#   for details.
require 'sensu-plugins-kubernetes/cli'
require 'sensu-plugins-kubernetes/cli/namespaced'
require 'sensu-plugin/metric/cli'
require 'uri'

class PodsMetrics < Sensu::Plugin::Metric::CLI::Graphite
  @options = Sensu::Plugins::Kubernetes::CLI.options.dup
  include Sensu::Plugins::Kubernetes::NamespacedCLI

  def run
    config[:scheme] = "#{URI(config[:api_server]).host}.pods"
    count = {}
    client = Sensu::Plugins::Kubernetes::CLI.new.client
    services = client.get_services(namespace: namespace)
    services.each do |s|
      selector_key = []
      count[s.metadata.name] = 0
      services.delete(s.metadata.name)
      s.spec.selector.to_h.each do |k, v|
        selector_key << "#{k}=#{v}"
      end
      pod = nil
      begin
        pod = client.get_pods(namespace: namespace, label_selector: selector_key.join(',').to_s)
      rescue KubeException => e
        critical 'API error: ' << e.message
      end
      next if pod.nil?
      pod.each do
        count[s.metadata.name] += 1
      end
    end
    count.each { |k, v| output "#{config[:scheme]}.#{k}", v }
    ok
  end
end
