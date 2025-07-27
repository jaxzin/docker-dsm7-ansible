# Synology DSM 7 Container Image for Ansible Molecule Testing

[![Build & Publish Docker Image](https://github.com/jaxzin/docker-dsm7-ansible/actions/workflows/docker-publish.yml/badge.svg)](https://github.com/jaxzin/docker-dsm7-ansible/actions/workflows/docker-publish.yml)

A Docker image for running Ansible Molecule tests, tailored for roles targeting Synology DSM 7.2.

This image provides an environment that mimics a Synology NAS running DSM 7.2, allowing you to test your Ansible roles 
in a containerized environment before deploying them to a real Synology device.

## Key Features

*   **DSM 7.2 Environment Parity:** Based on Ubuntu 20.04, with packages and versions carefully selected to match those found in Synology DSM 7.2.
*   **Python 2.7 & 3.10:** Includes both Python 2.7 and Python 3.10, reflecting the Python environments available on DSM.
*   **Stubbed Synology Commands:** Includes stubbed versions of `synoservice`, `synopkg`, and `synosystemctl` to allow roles that use these commands to run without errors.
*   **Pre-installed Ansible:** Comes with Ansible pre-installed, ready for use with Molecule.

## Usage

This image is intended to be used as a platform in your `molecule.yml` file.

### Molecule Configuration

Here is an example of how to use this image as a platform in your `molecule.yml` file with the Docker driver:

```yaml
---
dependency:
  name: galaxy
driver:
  name: docker
platforms:
  - name: instance
    image: ghcr.io/jaxzin/docker-dsm7-ansible:latest
    pre_build_image: true
provisioner:
  name: ansible
verifier:
  name: ansible
```

### Pulling the Image

You can also pull the image directly from the GitHub Container Registry:

```sh
docker pull ghcr.io/jaxzin/docker-dsm7-ansible:latest
```

## Fingerprinting

The `fingerprinting` directory contains scripts and Molecule tests used to compare the environment of this Docker image with a real Synology DSM 7.2 installation. This helps to ensure that the Docker environment is as accurate as possible.

Here is a snippet of the fingerprint output from the container:

```
=== OS Identification ===
majorversion="7"
minorversion="2"
productversion="7.2.2"
etc_issue=Ubuntu 20.04.6 LTS \n \l

=== Python Versions ===
python: Python 3.10.18
python2: Python 2.7.18
python3: Python 3.10.18

=== Package Managers ===
synopkg: present
synoservice: present
synosystemctl: present
dpkg: present
```

## Contributing

Contributions are welcome! Please feel free to open an issue or submit a pull request.

## License

This project is licensed under the MIT License.

