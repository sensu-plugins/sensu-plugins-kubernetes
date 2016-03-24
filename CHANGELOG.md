#Change Log
This project adheres to [Semantic Versioning](http://semver.org/).

This CHANGELOG follows the format listed at [Keep A Changelog](http://keepachangelog.com/)

## [Unreleased]
### Added 3/23/2016
- Added flags for authentication
- Added flags for SSL

### Added
- Added flag to ignore namespaces in check-kube-pods-pending
- check-kube-service-available.rb: Will not mark a service is failed if any needed pod is running and ready
- check-kube-service-available.rb: Added options to allow of pod pending for given time to be counted as valid
- check-kube-service-available.rb: Fixed scope issue in main block that would cause a nil error

## 0.0.1 - 2016-03-03
### Added
- initial release

[Unreleased]: https://github.com/sensu-plugins/sensu-plugins-kubernetes/compare/0.0.1...HEAD
