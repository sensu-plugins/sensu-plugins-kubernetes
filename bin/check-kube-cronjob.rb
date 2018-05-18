#! /usr/bin/env ruby
#
#   check-kube-cronjob
#
# DESCRIPTION:
# => Monitor if cronjob failed to execute successfully
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
# -n NAMESPACES,                   Exclude the specified list of namespaces
#     --exclude-namespace
# -i NAMESPACES,                   Include the specified list of namespaces, an
#     --include-namespace          empty list includes all namespaces
# -t, --timeout TIMEOUT            Threshold for pods to be in the pending state
# -f, --filter FILTER              Selector filter for pods to be checked
# -p, --pods PODS                  Optional list of pods to check.
#                                  Defaults to 'all'
#
# NOTES:
# => The filter used for the -f flag is in the form key=value. If multiple
#    filters need to be specfied, use a comma. ex. foo=bar,red=color
#
# LICENSE:
#   SendGrid did something here.
#   Released under the same terms as Sensu (the MIT license); see LICENSE
#   for details.
#

require 'sensu-plugins-kubernetes/cli'

class AllPodsAreReady < Sensu::Plugins::Kubernetes::CLI
  @options = Sensu::Plugins::Kubernetes::CLI.options.dup
  @options[:api_version][:default] = 'batch/v1'

  option :cronjob_list,
    description: 'List of cronjobs to check',
    short: '-c CRONJOBS',
    long: '--cronjobs',
    default: 'all'

  option :pending_timeout,
    description: 'Threshold for pods to be in the pending state',
    short: '-t TIMEOUT',
    long: '--timeout',
    proc: proc(&:to_i),
    default: 300

  option :exclude_namespace,
    description: 'Exclude the specified list of namespaces',
    short: '-n NAMESPACES',
    long: '--exclude-namespace',
    proc: proc { |a| a.split(',') },
    default: ''

  option :include_namespace,
    description: 'Include the specified list of namespaces',
    short: '-i NAMESPACES',
    long: '--include-namespace',
    proc: proc { |a| a.split(',') },
    default: ''

  def run
    all_cronjobs = []
    failed_cronjobs = []
    cronjob_list = parse_list(config[:cronjob_list])
    all_cronjobs = get_all_cronjobs

    all_cronjobs.each do |cronjob|
      jobs = get_jobs_from_cronjob(cronjob.metadata.name, cronjob.metdata.namespace)
      # job must have run, job must fail
      failed_cronjobs << cronjob.sort.last if jobs.condition.status == false # TODO verify selectors / status
    end

    if failed_pods.empty?
      ok 'All cronjobs ran successfully'
    else
      critical "Cronjobs have failed: #{failed_cronjobs.join(' ')}"
    end
  rescue KubeException => e
    critical 'API error: ' << e.message
  end

  def parse_list(list)
    return list.split(',') if list && list.include?(',')
    return [list] if list
    ['']
  end

  def should_exclude_namespace(namespace)
    return !config[:include_namespace].include?(namespace) unless config[:include_namespace].empty?
    config[:exclude_namespace].include?(namespace)
  end

  def get_jobs_from_cronjobs(name, namespace)
    job_client.get_jobs.select do |j|
      j.metadata.name =~ /#{name}-[[:digit:]]{10}$/ && j.metadata.name == namespace
    end
  end

  def get_all_cronjobs
    cronjob_client.get_cron_jobs.select do |cj|
      !should_exclude_namespace(cj.metadata.namespace) && (config[:cronjob_list] = ['all'] || config[:cronjob_list].include?('all'))
    end
  end

  def job_client
    @client_job_client ||= kubeclient(
      server: config[:api_server],
      version: 'batch/v1',
      incluster: config[:api_incluster],
      ca_file: config[:api_ca_file],
      client_cert_file: config[:api_client_cert],
      client_key_file: config[:api_client_key],
      username: config[:api_user],
      password: config[:api_password],
      token: config[:api_token],
      token_file: config[:api_token_file],
      kube_config: config[:kube_config]
    )
  rescue ArgumentError => e
    critical e.message
  end

  def cronjob_client
    @client_cronjob_client ||= kubeclient(
      server: config[:api_server],
      version: 'batch/v1beta1',
      incluster: config[:api_incluster],
      ca_file: config[:api_ca_file],
      client_cert_file: config[:api_client_cert],
      client_key_file: config[:api_client_key],
      username: config[:api_user],
      password: config[:api_password],
      token: config[:api_token],
      token_file: config[:api_token_file],
      kube_config: config[:kube_config]
    )
  rescue ArgumentError => e
    critical e.message
  end
end
