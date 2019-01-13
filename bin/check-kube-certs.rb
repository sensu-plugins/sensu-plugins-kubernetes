#! /usr/bin/env ruby
#
#   check-kube-certs
#
# DESCRIPTION:
# => Check if certificates generated by cert-manager are valid
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
#     --in-namespace               If running in K8S, operate in running namespace
# -n NAMESPACES,                   Exclude the specified list of namespaces
#     --exclude-namespace
# -i NAMESPACES,                   Include the specified list of namespaces, an
#     --include-namespace          empty list includes all namespaces
# -f, --filter FILTER              Selector filter for pods to be checked
#                                  Defaults to 'all'
# -e DAYS,
#    --expiration_window           Numberof days to notify before certificate expires
#
# NOTES:
# => The filter used for the -f flag is in the form key=value. If multiple
#    filters need to be specfied, use a comma. ex. foo=bar,red=color
#

require 'sensu-plugins-kubernetes/cli'
require 'sensu-plugins-kubernetes/cli/namespaced'

class CheckKubernetesCertificates < Sensu::Plugins::Kubernetes::CLI
  include Sensu::Plugins::Kubernetes::NamespacedCLI

  option :label_filter,
         description: 'Label selector for pods to be checked (example -- key1=value1,key2!=value2)',
         short: '-f FILTER',
         long: '--filter'

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

  option :expiration_window,
         description: 'Number of day to notify before certificate expires (default 7 days)',
         short: '-e DAYS',
         long: '--expiration-window',
         proc: proc { |a| a.to_i * 86_400 },
         default: 7

  def run
    all_certs = []
    bad_certs = []
    wonky_certs = []
    secrets = client.get_secrets(namespace: namespace)
    secrets.each do |secret|
      all_certs << secret if secret['metadata']['annotations'].to_s.include?('certmanager')
    end

    all_certs.each do |cert|
      loaded_cert = validate_cert(Base64.decode64(cert['data'][:'tls.crt']))
      time_now_utc = Time.now.utc
      cert_expiration = loaded_cert.not_after # Kube returns these in UTC

      if (cert_expiration - time_now_utc) < config[:expiration_window]
        bad_certs << cert['metadata']['name']
      end
    end

    if bad_certs.empty?
      ok 'All certificates are valid and are not expiring soon'
    elsif wonky_certs.any?
      warn "Error parsing cert(s): #{wonky_certs.join(' ')}"
    else
      critical "The following cert(s) are expiring in less than #{config[:expiration_window] / 86_400} days: #{bad_certs.join(' ')}"
    end
  rescue KubeException => e
    critical 'API error: ' << e.message
  end

  def validate_cert(cert)
    OpenSSL::X509::Certificate.new cert
  rescue StandardError => e
    wonky_certs << "Error Parsing: #{cert['metadata']['name']} #{e}"
  end

  def should_exclude_namespace(namespace)
    return !config[:include_namespace].include?(namespace) unless config[:include_namespace].empty?
    config[:exclude_namespace].include?(namespace)
  end
end
