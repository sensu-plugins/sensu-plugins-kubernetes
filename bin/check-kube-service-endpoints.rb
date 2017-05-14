#! /usr/bin/env ruby
#
#   check-kube-service-endpoints
#
# DESCRIPTION:
# => Check if your kube services are available to serve traffic by checking for services with empty endpoints.
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
#     --ca-file CA-FILE            CA file to verify API server cert
#     --cert CERT-FILE             Client cert to present
#     --key KEY-FILE               Client key for the client cert
#     --in-cluster                 Use service account authentication
# -p, --password PASSWORD          If user is passed, also pass a password
# -s, --api-server URL             URL to API server
#     --token TOKEN                Bearer token for authorization
#     --token-file TOKEN-FILE      File containing bearer token for authorization
# -u, --user USER                  User with access to API
#     --api-version VERSION        API version
#     --exclude-namespaces         Exclude the specified list of namespaces
#     --exclude-services           comma separated list of services to exclude
# -n, --namespaces NAMESPACES      comma separated list of namespaces to check (default all)
# -l, --services SERVICES          comma separated list of services to check (default all)
# -t, --types TYPES                comma separated list of service types to check (default: ClusterIP,LoadBalancer)
# -v, --verbose                    verbose output
#
# NOTES:
#
# LICENSE:
#   Joe Miller <joeym@joey.net>
#   Released under the same terms as Sensu (the MIT license); see LICENSE
#   for details.
#

require 'sensu-plugins-kubernetes/cli'

class AllServicesUp < Sensu::Plugins::Kubernetes::CLI
  @options = Sensu::Plugins::Kubernetes::CLI.options.dup

  option :service_list,
         description: 'comma separated list of services to check (default all)',
         short: '-l SERVICES',
         long: '--services',
         proc: proc { |a| a.split(',') },
         default: 'all'

  option :exclude_services,
         description: 'comma separated list of services to exclude',
         long: '--exclude-services',
         proc: proc { |a| a.split(',') },
         default: 'all'

  option :namespaces,
         description: 'comma separated list of namespaces to check (default all)',
         short: '-n NAMESPACES',
         long: '--namespaces',
         proc: proc { |a| a.split(',') },
         default: 'all'

  option :exclude_namespace,
         description: 'Exclude the specified list of namespaces',
         long: '--exclude-namespaces',
         proc: proc { |a| a.split(',') },
         default: ''

  option :service_types,
         description: 'comma separated list of service types to check (default: ClusterIP,LoadBalancer)',
         short: '-t TYPES',
         long: '--types',
         proc: proc { |a| a.downcase.split(',') },
         default: %w(clusterip loadbalancer)

  option :verbose,
         description: 'verbose output',
         short: '-v',
         long: '--verbose',
         boolean: true,
         default: false

  def run
    puts "config: #{config.inspect}" if config[:verbose]
    failed_services = []

    services = client.get_services
    services.each do |s|
      # namespace whitelist / blacklisting
      next if config[:exclude_namespace].include?(s.metadata.namespace)
      next unless config[:namespaces].include?(s.metadata.namespace) || config[:namespaces].include?('all')

      # filter service types
      next unless config[:service_types].include?(s.spec.type.downcase)

      # service whitelist / blacklisting
      next if config[:exclude_services].include?(s.metadata.name)
      next unless config[:service_list].include?(s.metadata.name) || config[:service_list].include?('all')

      puts "#{s.metadata.namespace} #{s.metadata.name} #{s.spec.type}" if config[:verbose]

      begin
        ep = client.get_endpoint(s.metadata.name, s.metadata.namespace)
      rescue
        puts "#{s.metadata.name} couldn't find matching endpoint" if config[:verbose]
        next
      end

      if ep.subsets.empty?
        failed_services << format('%s/%s', s.metadata.namespace, s.metadata.name)
      end
    end

    if failed_services.empty?
      ok 'All services are available'
    else
      critical "Services unavailable: #{failed_services.join("\n")}"
    end
  rescue KubeException => e
    critical 'API error: ' << e.message
  end
end
