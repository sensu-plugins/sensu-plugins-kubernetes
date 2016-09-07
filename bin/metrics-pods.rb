#! /usr/bin/env ruby
#
#   pod-metrics
#
# DESCRIPTION:
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

class PodsMetrics < Sensu::Plugins::Kubernetes::CLI
  @options = Sensu::Plugins::Kubernetes::CLI.options.dup

  option :service_list,
         description: 'List of services to check',
         short: '-l SERVICES',
         long: '--list',
         required: true

  def run
    services = client.get_services
    s.each do |a|
      selector_key = []
      services.delete(a.metadata.name)
      a.spec.selector.to_h.each do |k,v|
        selector_key << "#{k}=#{v}"
      end
      pod = nil
      count = 0
      begin
        pod = client.get_pods(label_selector: selector_key.join(',').to_s)
      rescue
        puts 'There was an error'
      end
      next if pod.nil?
      pod.each do |p|
        puts p
      end
    end
  end

  def parse_list(list)
    return list.split(',') if list && list.include?(',')
    return [list] if list
    ['']
  end

end
