# Docker DSM7 Ansible Fingerprinting

This project is designed to facilitate the search for a base Docker image that closely mirrors the environment of 
Synology DSM 7. The primary goal is to identify a compatible and minimal base image for building and testing 
applications intended for deployment on Synology NAS devices.

## How it Works

The project leverages Ansible and Molecule to provision a Docker container and execute a fingerprinting script. 
This script, `dsm-full-fingerprint.sh`, gathers detailed information about the operating system, installed packages, 
and system configuration. The output of this script is then used to compare different base images and identify the one 
that provides the most similar environment to Synology DSM 7.

## Prerequisites

*   [Docker](https://docs.docker.com/engine/install/) or [Docker Desktop](https://docs.docker.com/desktop/)
*   [Python 3.13 or later](https://www.python.org/downloads/)
*   [UV](https://docs.astral.sh/uv/getting-started/installation/)

## Running the Tests

To initiate the fingerprinting process, execute the following command:

```bash
make fingerprint
```

This command will:

1. Spin up a Docker container based on the image specified in `molecule/default/molecule.yml`.
2. Run the Ansible playbook defined in `molecule/default/converge.yml`.
3. Execute the `dsm-full-fingerprint.sh` script inside the container.
4. Output the results to the `molecule/default/output/` directory.
5. Clean up the Docker container after the test run.

## Output Logs

The output logs from the fingerprinting script are stored in the `molecule/default/output/` directory. 
Each log file is named after the base image being tested, for example:

*   `debian10-fingerprint.log`
*   `debian11-fingerprint.log`

These logs contain the detailed system information collected during the test run and can be used for 
comparison and analysis.
I then ran them through an LLM for analysis, which provided insights into the similarities and 
differences between the base images and Synology DSM 7.
