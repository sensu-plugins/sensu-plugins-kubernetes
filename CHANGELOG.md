#Change Log
This project adheres to [Semantic Versioning](http://semver.org/).

This CHANGELOG follows the format listed at [Keep A Changelog](http://keepachangelog.com/)

## [Unreleased]
- check-kube-service-available.rb: Allow checking of all services by default. Services without a selector will be checked for an  endpoint.

## [0.1.1] - 2016-05-17
### Fixed
- cli.rb: Fixed typo in critical call

## [0.1.0] - 2016-05-15
### Added
- Added flag to ignore namespaces in check-kube-pods-pending
- check-kube-service-available.rb: Will not mark a service is failed if any needed pod is running and ready
- check-kube-service-available.rb: Added options to allow of pod pending for given time to be counted as valid
- Factored all checks to share a common base class for connecting to Kubernetes
- Added flags to specify certificate authority and Kubernetes bearer token
- Added flags to specify client certificate/key and in-cluster support
- Support for Ruby 2.3

### Fixed
- check-kube-service-available.rb: Fixed scope issue in main block that would cause a nil error

### Changed
- Update to Rubocop 0.40 and cleanup
- Update to kubeclient 1.1.3

## 0.0.1 - 2016-03-03
### Added
- initial release

[Unreleased]: https://github.com/sensu-plugins/sensu-plugins-kubernetes/compare/0.1.1...HEAD
[0.1.1]: https://github.com/sensu-plugins/sensu-plugins-kubernetes/compare/0.1.0...0.1.1
[0.1.0]: https://github.com/sensu-plugins/sensu-plugins-kubernetes/compare/0.0.1...0.1.0
