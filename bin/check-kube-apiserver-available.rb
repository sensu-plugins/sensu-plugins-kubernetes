#! /usr/bin/env ruby
# frozen_string_literal: false

#   check-kube-apiserver-available.rb
#
# DESCRIPTION:
# => Check if the Kubernetes API server is up
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

class ApiServerIsAvailable < Sensu::Plugins::Kubernetes::CLI
  @options = Sensu::Plugins::Kubernetes::CLI.options.reject { |k| k == :api_version }

  def run
    if healthy?
      ok 'Kubernetes API server is available'
    end
    critical 'Kubernetes API server is unavailable'
  end

  # TODO: replace this method when it's added to kubeclient
  def healthy?
    client.handle_exception do
      client.create_rest_client('/healthz').get(client.headers)
    end
    true
  rescue KubeException
    false
  end
end
