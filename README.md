## Sensu-Plugins-kubernetes

[![Build Status](https://travis-ci.org/sensu-plugins/sensu-plugins-kubernetes.svg?branch=master)](https://travis-ci.org/sensu-plugins/sensu-plugins-kubernetes)
[![Gem Version](https://badge.fury.io/rb/sensu-plugins-kubernetes.svg)](http://badge.fury.io/rb/sensu-plugins-kubernetes)
[![Code Climate](https://codeclimate.com/github/sensu-plugins/sensu-plugins-kubernetes/badges/gpa.svg)](https://codeclimate.com/github/sensu-plugins/sensu-plugins-kubernetes)
[![Test Coverage](https://codeclimate.com/github/sensu-plugins/sensu-plugins-kubernetes/badges/coverage.svg)](https://codeclimate.com/github/sensu-plugins/sensu-plugins-kubernetes)
[![Dependency Status](https://gemnasium.com/sensu-plugins/sensu-plugins-kubernetes.svg)](https://gemnasium.com/sensu-plugins/sensu-plugins-kubernetes)
[![Codeship Status for sensu-plugins/sensu-plugins-kubernetes](https://codeship.com/projects/8345d1d0-2e9d-0133-1ce3-3a2a4d3529b0/status?branch=master)](https://codeship.com/projects/99159)

## Functionality
This provides functionality to check node and pod status as well as api and service availability.

## Files
- bin/check-kube-nodes-ready.rb
- bin/check-kube-apiserver-available.rb
- bin/check-kube-pods-pending.rb
- bin/check-kube-service-available.rb
- bin/handler-kube-pod.rb

## Usage
: check-kube-nodes-ready.rb -s SERVER -v API_VERSION
: check-kube-apiserver-available.rb -s SERVER
: check-kube-pods-pending.rb -s SERVER
: check-kube-service-available.rb -s SERVER  -l SERVICE1,SERVICE2
## Installation

[Installation and Setup](http://sensu-plugins.io/docs/installation_instructions.html)

## Notes
