## Sensu-Plugins-kubernetes

[![Build Status](https://travis-ci.org/sensu-plugins/sensu-plugins-kubernetes.svg?branch=master)](https://travis-ci.org/sensu-plugins/sensu-plugins-kubernetes)
[![Gem Version](https://badge.fury.io/rb/sensu-plugins-kubernetes.svg)](http://badge.fury.io/rb/sensu-plugins-kubernetes)
[![Dependency Status](https://gemnasium.com/sensu-plugins/sensu-plugins-kubernetes.svg)](https://gemnasium.com/sensu-plugins/sensu-plugins-kubernetes)

## Functionality
This provides functionality to check node and pod status as well as api and service availability.

## Files
- bin/check-kube-nodes-ready.rb
- bin/check-kube-apiserver-available.rb
- bin/check-kube-pods-pending.rb
- bin/check-kube-service-available.rb
- bin/check-kube-pods-runtime.rb
- bin/check-kube-pods-running.rb
- bin/check-kube-pods-restarting.rb
- bin/handler-kube-pod.rb
- bin/metrics-pods.rb

## Usage

**check-kube-nodes-ready.rb**
```
Usage: check-kube-nodes-ready.rb (options)
        --ca-file CA-FILE            CA file to verify API server cert
        --cert CERT-FILE             Client cert to present
        --key KEY-FILE               Client key for the client cert
        --in-cluster                 Use service account authentication
    -p, --password PASSWORD          If user is passed, also pass a password
    -s, --api-server URL             URL to API server
    -t, --token TOKEN                Bearer token for authorization
        --token-file TOKEN-FILE      File containing bearer token for authorization
    -u, --user USER                  User with access to API
    -v, --api-version VERSION        API version
        --kube-config KUBECONFIG     Path to a kube config file
        --exclude-nodes              Exclude the specified nodes (comma separated list)
                                     Exclude wins when a node is in both include and exclude lists
        --include-nodes              Include the specified nodes (comma separated list), an
                                     empty list includes all nodes
```

**check-kube-apiserver-available.rb**
```
Usage: check-kube-apiserver-available.rb (options)
        --ca-file CA-FILE            CA file to verify API server cert
        --cert CERT-FILE             Client cert to present
        --key KEY-FILE               Client key for the client cert
        --in-cluster                 Use service account authentication
    -p, --password PASSWORD          If user is passed, also pass a password
    -s, --api-server URL             URL to API server
    -t, --token TOKEN                Bearer token for authorization
        --token-file TOKEN-FILE      File containing bearer token for authorization
    -u, --user USER                  User with access to API
        --kube-config KUBECONFIG     Path to a kube config file
```

**check-kube-pods-pending.rb**
```
Usage: check-kube-pods-pending.rb (options)
        --ca-file CA-FILE            CA file to verify API server cert
        --cert CERT-FILE             Client cert to present
        --key KEY-FILE               Client key for the client cert
        --in-cluster                 Use service account authentication
        --password PASSWORD          If user is passed, also pass a password
    -s, --api-server URL             URL to API server
        --token TOKEN                Bearer token for authorization
        --token-file TOKEN-FILE      File containing bearer token for authorization
    -u, --user USER                  User with access to API
    -v, --api-version VERSION        API version
    -n NAMESPACES,                   Exclude the specified list of namespaces
        --exclude-namespace
    -i NAMESPACES,                   Include the specified list of namespaces, an 
        --include-namespace          empty list includes all namespaces
        --exclude-nodes              Exclude the specified nodes (comma separated list)
                                     Exclude wins when a node is in both include and exclude lists
        --include-nodes              Include the specified nodes (comma separated list), an
                                     empty list includes all nodes
    -t, --timeout TIMEOUT            Threshold for pods to be in the pending state
    -f, --filter FILTER              Selector filter for pods to be checked
    -p, --pods PODS                  List of pods to check
    -r, --restart COUNT              Threshold for number of restarts allowed
        --kube-config KUBECONFIG     Path to a kube config file
```

**check-kube-service-available.rb**
```
Usage: check-kube-service-available.rb (options)
        --ca-file CA-FILE            CA file to verify API server cert
        --cert CERT-FILE             Client cert to present
        --key KEY-FILE               Client key for the client cert
        --in-cluster                 Use service account authentication
        --password PASSWORD          If user is passed, also pass a password
    -s, --api-server URL             URL to API server
    -t, --token TOKEN                Bearer token for authorization
        --token-file TOKEN-FILE      File containing bearer token for authorization
    -u, --user USER                  User with access to API
    -v, --api-version VERSION        API version
    -p, --pending SECONDS            Time (in seconds) a pod may be pending for and be valid
    -l, --list SERVICES              List of services to check (required)
        --kube-config KUBECONFIG     Path to a kube config file
```

**check-kube-pods-runtime.rb**
```
Usage: check-kube-pods-runtime.rb (options)
        --ca-file CA-FILE            CA file to verify API server cert
        --cert CERT-FILE             Client cert to present
        --key KEY-FILE               Client key for the client cert
        --in-cluster                 Use service account authentication
        --password PASSWORD          If user is passed, also pass a password
    -s, --api-server URL             URL to API server
    -t, --token TOKEN                Bearer token for authorization
        --token-file TOKEN-FILE      File containing bearer token for authorization
    -u, --user USER                  User with access to API
    -v, --api-version VERSION        API version
    -c, --critical COUNT             Threshold for Pods to be critical
    -f, --filter FILTER              Selector filter for pods to be checked
    -p, --pods PODS                  List of pods to check
    -w, --warn TIMEOUT               Threshold for pods to be in the pending state
        --kube-config KUBECONFIG     Path to a kube config file
```

**check-kube-pods-running.rb**
```
Usage: ./check-kube-pods-running.rb (options)
        --ca-file CA-FILE            CA file to verify API server cert
        --cert CERT-FILE             Client cert to present
        --key KEY-FILE               Client key for the client cert
        --in-cluster                 Use service account authentication
        --password PASSWORD          If user is passed, also pass a password
    -s, --api-server URL             URL to API server
    -t, --token TOKEN                Bearer token for authorization
        --token-file TOKEN-FILE      File containing bearer token for authorization
    -u, --user USER                  User with access to API
    -v, --api-version VERSION        API version
    -n NAMESPACES,                   Exclude the specified list of namespaces
        --exclude-namespace
    -i NAMESPACES,                   Include the specified list of namespaces, an 
        --include-namespace          empty list includes all namespaces
        --exclude-nodes              Exclude the specified nodes (comma separated list)
                                     Exclude wins when a node is in both include and exclude lists
        --include-nodes              Include the specified nodes (comma separated list), an
                                     empty list includes all nodes
    -f, --filter FILTER              Selector filter for pods to be checked
    -p, --pods PODS                  List of pods to check
        --kube-config KUBECONFIG     Path to a kube config file
```

**check-kube-pods-restarting.rb**

```
Usage: ./check-kube-pods-restarting.rb (options)
        --ca-file CA-FILE            CA file to verify API server cert
        --cert CERT-FILE             Client cert to present
        --key KEY-FILE               Client key for the client cert
        --in-cluster                 Use service account authentication
        --password PASSWORD          If user is passed, also pass a password
    -s, --api-server URL             URL to API server
    -t, --token TOKEN                Bearer token for authorization
        --token-file TOKEN-FILE      File containing bearer token for authorization
    -u, --user USER                  User with access to API
    -v, --api-version VERSION        API version
    -n NAMESPACES,                   Exclude the specified list of namespaces
        --exclude-namespace
    -i NAMESPACES,                   Include the specified list of namespaces, an 
        --include-namespace          empty list includes all namespaces
        --exclude-nodes              Exclude the specified nodes (comma separated list)
                                     Exclude wins when a node is in both include and exclude lists
        --include-nodes              Include the specified nodes (comma separated list), an
                                     empty list includes all nodes
    -f, --filter FILTER              Selector filter for pods to be checked
    -p, --pods PODS                  List of pods to check
    -r, --restart COUNT              Threshold for number of restarts allowed
        --kube-config KUBECONFIG     Path to a kube config file
```

**handler-kube-pod.rb**
```
Usage: handler-kube-pod.rb (options)
    -j, --json JSONCONFIG            Configuration name
```

`JSONCONFIG` defaults to `k8s`.

```
{
    "k8s": {
        "server": "https://kubernetes/",
        "version": "v1",
        "incluster": false,
        "ca_file": "/certs/ca.crt.pem",
        "client_cert_file": "/certs/client.crt.pem",
        "client_key_file": "/private/client.key.pem",
        "username": "alice",
        "password": "secret",
        "token": "incomprehensible.token.string",
        "token_file": "/secret/token"
    }
}
```

**metrics-pods**
```
Usage: metrics-pods.rb (options)
        --ca-file CA-FILE            CA file to verify API server cert
        --cert CERT-FILE             Client cert to present
        --key KEY-FILE               Client key for the client cert
        --in-cluster                 Use service account authentication
        --password PASSWORD          If user is passed, also pass a password
        -s, --api-server URL             URL to API server
        -t, --token TOKEN                Bearer token for authorization
        --token-file TOKEN-FILE      File containing bearer token for authorization
        -u, --user USER                  User with access to API
        -v, --api-version VERSION        API version
            --kube-config KUBECONFIG     Path to a kube config file
```

`api_server` and `api_version` can still be used for backwards compatibility,
but `server` and `version` will take precedence.

## Installation

[Installation and Setup](http://sensu-plugins.io/docs/installation_instructions.html)

## Notes

Of the Kubernetes connection options:
```
--api-server URL             URL to API server
--api-version VERSION        API version
--in-cluster                 Use service account authentication
--ca-file CA-FILE            CA file to verify API server cert
--cert CERT-FILE             Client cert to present
--key KEY-FILE               Client key for the client cert
--user USER                  User with access to API
--password PASSWORD          If user is passed, also pass a password
--token TOKEN                Bearer token for authorization
--token-file TOKEN-FILE      File containing bearer token for authorization
--kube-config KUBECONFIG     Path to a kube config file
```
Only the API server option is required, however it does default to the `KUBERNETES_MASTER` environment variable, or you can use the in-cluster option. The other options are to be used as needed.

The default API version is `v1`.

The in-cluster option provides defaults for:
- The server URL, using the `KUBERNETES_SERVICE_HOST` and `KUBERNETES_SERVICE_PORT` environment variables.
- The API CA file, using the service account CA file if it exists. (`/var/run/secrets/kubernetes.io/serviceaccount/ca.crt`)
- The API token, using the service account token file. (`/var/run/secrets/kubernetes.io/serviceaccount/token`)

If the Kubernetes API provides a server certificate, it is only validated if a CA file is provided.

The client certificate and client private key are optional, but if one is provided then the other must also be provided.

Only one of the authentication methods (user, token, or token file) can be used.
For example, using a username and a token, or a token and a token file, will produce an error.

If the 'user' authentication method is used, a password must also be provided.

The kubeconfig options enable the usage of a kubeconfig file, which is a yaml file which defines the authentication and TLS config. More information about kubeconfig files can be found in the [Kubernetes Docs](https://kubernetes.io/docs/tasks/access-application-cluster/authenticate-across-clusters-kubeconfig/)
