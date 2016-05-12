#! /usr/bin/env ruby
#
#   check-kube-nodes-ready.rb
#
# DESCRIPTION:
# => Check if the Kubernetes nodes are in a ready to use state
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
# -s SERVER - The kubernetes SERVER
# -v VERSION - The kubernetes api VERSION. Defaults to v1
#
# LICENSE:
#   Kel Cecil <kelcecil@praisechaos.com>
#   Released under the same terms as Sensu (the MIT license); see LICENSE
#   for details.
#

require 'sensu-plugins-kubernetes/cli'

class AllNodesAreReady < Sensu::Plugins::Kubernetes::CLI
  @options = Sensu::Plugins::Kubernetes::CLI.options.dup

  def run
    failed_nodes = []
    client.get_nodes.each do |node|
      item = node.status.conditions.detect { |condition| condition.type == 'Ready' }
      if item.nil?
        warning "#{node.name} does not have a status"
      elsif item.status != 'True'
        failed_nodes << node.metadata.name
      end
    end

    if failed_nodes.empty?
      ok 'All nodes are reporting as ready'
    end
    critical "Nodes are not ready: #{failed_nodes.join(' ')}"
  rescue KubeException => e
    critical 'API error: ' << e.message
  end
end
