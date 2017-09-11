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
# -s, --api-server URL             URL to API server
# -v, --api-version VERSION        API version. Defaults to 'v1'
#     --in-cluster                 Use service account authentication
#     --ca-file CA-FILE            CA file to verify API server cert
#     --cert CERT-FILE             Client cert to present
#     --key KEY-FILE               Client key for the client cert
# -u, --user USER                  User with access to API
# -p, --password PASSWORD          If user is passed, also pass a password
# -t, --token TOKEN                Bearer token for authorization
#     --token-file TOKEN-FILE      File containing bearer token for authorization
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
        failed_nodes << node.metadata.name unless node.spec.unschedulable
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
