# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](http://keepachangelog.com/en/1.0.0/)
and this project adheres to [Semantic Versioning](http://semver.org/spec/v2.0.0.html).

Types of changes are:

* **Added** for new features.
* **Changed** for changes in existing functionality.
* **Deprecated** for soon-to-be removed features.
* **Removed** for now removed features.
* **Fixed** for any bug fixes.
* **Security** in case of vulnerabilities.

## Unreleased

## 1.0.4 - 2020-08-18

## Changed

* Updated terraform code to utilise new google-beta provider support for provisioning Serverless Network Endpoint Groups. This has simplified the code somewhat.
* We are still reliant on some deprecated functionality in the ``null_resource`` attribute to provision the backend service since currently that does not support serverless NEGs
* Upgrade to terraform 0.13 is currently blocked due to the previous bullet point.

## 1.0.3 - 2020-07-15

## Changed

* Added link to medium tutorial from README.md file.

## 1.0.2 - 2020-07-15

## Changed

* Updated the terraform to use ``depends_on`` to fix the race condition issue with Google API and services.
* Updated the README and CHANGELOG to reflect these changes.

## 1.0.1 - 2020-07-15

## Changed

* Updated the README to inform of a race condition surrounding the enabling of Google APIs and services.

## 1.0.0 - 2020-07-15

## Added

* Initial terraform codebase to accompany the tutorial
* Basic CI/CD using Travis
* LICENSE, README, CODE_OF_CONDUCT and CHANGELOG added.
