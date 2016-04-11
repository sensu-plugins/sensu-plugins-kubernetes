## Sensu-Plugins-kubernetes

[![Build Status](https://travis-ci.org/sensu-plugins/sensu-plugins-kubernetes.svg?branch=master)](https://travis-ci.org/sensu-plugins/sensu-plugins-kubernetes)
[![Gem Version](https://badge.fury.io/rb/sensu-plugins-kubernetes.svg)](http://badge.fury.io/rb/sensu-plugins-kubernetes)
[![Code Climate](https://codeclimate.com/github/sensu-plugins/sensu-plugins-kubernetes/badges/gpa.svg)](https://codeclimate.com/github/sensu-plugins/sensu-plugins-kubernetes)
[![Test Coverage](https://codeclimate.com/github/sensu-plugins/sensu-plugins-kubernetes/badges/coverage.svg)](https://codeclimate.com/github/sensu-plugins/sensu-plugins-kubernetes)
[![Dependency Status](https://gemnasium.com/sensu-plugins/sensu-plugins-kubernetes.svg)](https://gemnasium.com/sensu-plugins/sensu-plugins-kubernetes)

## Functionality
This provides functionality to check node and pod status as well as api and service availability.

## Files
- bin/check-kube-nodes-ready.rb
- bin/check-kube-apiserver-available.rb
- bin/check-kube-pods-pending.rb
- bin/check-kube-service-available.rb
- bin check/kube-pods-runtime.rb
- bin/handler-kube-pod.rb

## Usage
```
check-kube-nodes-ready.rb -s SERVER -v API_VERSION -u USER -p PASSWORD -t TOKEN -m SSL_VERIFY_MODE
check-kube-apiserver-available.rb -s SERVER
check-kube-pods-pending.rb -s SERVER -u USER -p PASSWORD -k TOKEN -m SSL_VERIFY_MODE
check-kube-service-available.rb -s SERVER  -l SERVICE1,SERVICE2 -u USER -p PASSWORD -t TOKEN -m SSL_VERIFY_MODE
```
## Installation

[Installation and Setup](http://sensu-plugins.io/docs/installation_instructions.html)

## Notes
