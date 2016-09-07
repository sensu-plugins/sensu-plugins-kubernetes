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
require 'socket'

class PodsMetrics < Sensu::Plugins::Kubernetes::CLI
  @options = Sensu::Plugins::Kubernetes::CLI.options.dup
  option :scheme,
       description: 'Metric naming scheme, text to prepend to metric',
       short: '-s SCHEME',
       long: '--scheme SCHEME',
       default: "#{Socket.gethostname}.pod"

  def run
    pod_counts = []
    count = Hash.new
    services = client.get_services
    services.each do |s|
      selector_key = []
      count[s.metadata.name] = 0
      services.delete(s.metadata.name)
      s.spec.selector.to_h.each do |k,v|
        selector_key << "#{k}=#{v}"
      end
      pod = nil
      begin
        pod = client.get_pods(label_selector: selector_key.join(',').to_s)
      rescue
        puts 'There was an error'
      end
      next if pod.nil?
      pod.each do |p|
        count[s.metadata.name] += 1
      end
    end
    count.size.times { |k,v| output "#{config[:scheme]}.#{k}", v}
    puts "DEBUG #{count}"
    puts "DEBUG #{output}"
    ok
  end

  def parse_list(list)
    return list.split(',') if list && list.include?(',')
    return [list] if list
    ['']
  end

end
