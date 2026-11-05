# Ubuntu Cloud Workspace

This repository is intended for a **cloud-hosted Linux workspace**.

## Design requirement

- All project source code, packages, workspaces, and runtime data must live on cloud storage / cloud compute.
- Android phone storage must be used only for the Termux app and temporary SSH/client configuration.
- Termux is a terminal client only. It must not download or install a Kali root filesystem locally.
- Do not run local NetHunter, proot-distro, or large package installations on the phone.

## Cloud architecture

The intended workflow is:

1. Provision a remote Linux machine or cloud development environment.
2. Keep the Git repository and working files on that remote machine.
3. Connect from Android using Termux over SSH.
4. If a desktop is required, run the desktop and remote-access service on the cloud machine and connect from the phone using a suitable remote desktop client.

## Important

A persistent cloud machine requires an actual cloud compute provider. GitHub repository storage alone is not a running Linux machine. GitHub Actions runners are temporary CI workers and are not a persistent interactive Kali desktop.

The existing `.devcontainer/` configuration is retained for reference, but it is Codespaces-specific and is not required by the Termux SSH-client workflow.

No local Kali installation script is provided in this repository, intentionally.
