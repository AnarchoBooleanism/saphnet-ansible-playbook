# saphnet-ansible-playbook
The Ansible playbook for the Saphnet Homelab/Home Server

Hello! These are the various Ansible playbooks that are used to automate procedures, such as deployment and updating, for the various machines that make up the Sapphic Homelab/Home Server, whether they are NixOS VMs or remote VPSes. These playbooks can be run on any machine that has network access to the systems involved (e.g. Proxmox hosts).

Note that, for NixOS machines, this playbook heavily relies on [saphnet-nixos-configs](https://github.com/AnarchoBooleanism/saphnet-nixos-configs) for their actual internal configurations.

## Quick breakdown

All relevant machines have an entry as hosts in the main Ansible inventory file, `inventory/main.yaml`, with a name for each host (to refer to within Ansible), as well as the actual (network) hostnames for Ansible to connect to. Each machine can also belong to groups (which can be nested): for example, the host, `control_server_main`, is under the `control_server` group (which is a special group dedicated for just `control_server_main`), which is under the `nixos_hosts` group. Ansible playbooks can target specific hosts and host groups.

Each host and host group has their own YAML file for variables. Variables hold the values that are used for the exact configuration of each machine and each procedure (playbook), such as hardware allocations, usernames, and version numbers. Files for host variables are in the `host_vars` directory, while files for host group variables are in the `group_vars` directory. Without exception, the names of the files for variables exactly match the names of the host/host groups that they are targeted to (for example, the file for the `nixos_vms` host group is `group_vars/nixos_vms.yaml`).

There are also files for secrets (e.g. passwords and SSH keys), which are Ansible vault files in the `secrets` directory. They, typically, are files that are dedicated to specific hosts, but they can also be files for secrets that are shared across multiple machines or types of procedures. Each vault file has its own vault ID assigned to it, typically named after the file's name; each vault ID has its own password (for encryption/decryption purposes), as well, which all will need to be handled when the relevant Ansible playbook is run.

Each playbook has its own subdirectory under the `playbooks` directory. Typically, each playbook is split into a `main.yaml` file (the playbook's entrypoint) and an `internal-loop.yaml` file. To run a playbook, you just need to specify the `main.yaml` file with the `ansible-playbook` command. The `main.yaml` file contains the steps that need to be done before the main per-host loop (e.g. getting secrets), the calling of the `internal-loop.yaml` for each host, and the steps that are done after all hosts are iterated over. The `internal-loop.yaml` file contains the steps that are done for each individual host.

As well, these playbooks can use files from the `common_files` directory; these files are often Jinja2 template files, for dynamic variable substition. For example, the `common_files/komodo-periphery` directory holds the files needed to run Komodo Periphery with Docker Compose; the `vps-main-provision` playbook clones these files to the VPS, dynamically inserting host-specific values that are needed for an actual deployment.

## Useful commands
- For editing Ansible vault files (for secrets): `EDITOR=nano ansible-vault edit --vault-id <VAULT-ID>@prompt secrets/<VAULT-FILE>.yaml`
  - NOTE: This will prompt you for a password! Make sure you use the correct password for the vault ID involved, and that the vault ID itself matches what the vault file uses. Typically, the vault ID is the same as the name of the vault file itself (e.g. the vault ID of `control-server.yaml` would be `control-server`).
- For encrypting unencrypted Ansible vault files: `ansible-vault encrypt --vault-id <VAULT-ID>@prompt secrets/<VAULT-FILE>.yaml`
  - NOTE: Again, this will prompt you for a password! Since you are defining the vault ID used here, make sure the vault ID matches what you want to use, and that you use the password you have in mind for the vault ID.
- For running an Ansible playbook: `ansible-playbook playbooks/<PLAYBOOK-NAME>/main.yaml`
- For running an Ansible playbook that requires a vault password: `ansible-playbook --ask-vault-pass playbooks/<PLAYBOOK-NAME>/main.yaml`
- For running an Ansible playbook that requires passwords for multiple vault IDs: `ansible-playbook --vault-id <VAULT-ID-1>@prompt --vault-id <VAULT-ID-2>@prompt playbooks/<PLAYBOOK-NAME>/main.yaml`
  - You can add as many vault IDs as needed (you will need to manually enter the password for each vault, however) by adding extra `--vault-id <VAULT-ID>@prompt` arguments.
- For verbosely running an Ansible playbook (for more log output): `ansible-playbook -vv playbooks/<PLAYBOOK-NAME>/main.yaml`
  - NOTE: You can use as little or as much verbosity as you desire: you can use `-v` for one level of verbosity beyond the default, and you can go all the way to `-vvvv` for maximum verbosity.
- For running an Ansible playbook for a specific host, for playbooks that target multiple hosts (e.g. `nixos-update`): `ansible-playbook playbooks/<PLAYBOOK-NAME>/main.yaml -e "target_<HOST-TYPE-NAME>_name=<HOST-NAME>"`
  - NOTE: What `target_<HOST-TYPE-NAME>_name` looks like depends on the playbook! For example, in `nixos-update`, it would be `target_vm_name`, while, in `vps-main-provision`, it would be `target_vps_name`.
  - NOTE: Make sure that the name of the host matches a valid host name in the Ansible inventory, and that the host is part of the group(s) targeted by the playbook!

### Example commands
- For running `nixos-proxmox-vm-deploy` for just the `control_server_main` host, at level 2 for verbosity: `ansible-playbook --vault-id control-server@prompt --vault-id proxmox@prompt -vv playbooks/nixos-proxmox-vm-deploy/main.yaml -e "target_vm_name=control_server_main"`
- For running `nixos-update` for all hosts, at level 2 for verbosity (assuming the exhaustive list of VMs are `control_server`, `docker_host_core`, `docker_host_pve3`, and `docker-host-pve4`): `ansible-playbook --vault-id ansible@prompt --vault-id control-server@prompt --vault-id docker-host-core@prompt --vault-id docker-host-pve3@prompt --vault-id docker-host-pve4@prompt playbooks/nixos-update/main.yaml -vv`
- For running `vps-main-provision` for just the `vps1` host, at level 2 for verbosity: `ansible-playbook --vault-id vps1@prompt -vv playbooks/vps-main-provision/main.yaml -e "target_vm_name=control_server_main"`

## Note on using Ansible (+ Nix)
To run the Ansible playbooks in this repository, you will need to have Ansible installed on your system's environment, whether through your system's package manager or through Python (via `pip`). Alongside Ansible, you will also need to have the `community.general` collection installed, to access functionality for Proxmox and more; the `community.general` collection is generally included with complete Ansible installations, but it, itself, is not part of `ansible-core`.

If running playbooks that make use of Nix (e.g. `nixos-proxmox-vm-deploy`, for deploying NixOS VMs on Proxmox hosts), you will also need to have Nix installed on your system's environment; as well, Nix will need to be configured with `flakes`, `nix-commands`, and `pipe-operators` enabled in `experimental-features`, within your `nix.conf` file (or your NixOS configuration).

### Using `ansible-shell.sh` (Docker-based approach)
If, for whatever reason, you desire to run the playbooks in a Docker container, this repository includes a shell script, `ansible-shell.sh`, that automatically sets up a Docker container, with Ansible and Nix available, through which you can run any shell command; `ansible-shell.sh` also configures the container to have access to the working directory (generally, the repository's directory). The only requirement is that Docker (or an equivalent container host) is installed and enabled on your environment.

The default behavior, when given no extra arguments, of `ansible-shell.sh` is to enter an interactive Bash shell session. In this shell, you are able to run any number of commands of your choice.

When given any number of arguments, `ansible-shell.sh` will treat it as a command to be immediately run (within Bash) within the Docker container. This means that, for any Ansible command, you are able to prepend `./ansible-shell.sh`, and the shell will run the command within the Docker container. For example, if you want to run `ansible-playbook playbooks/nixos-proxmox-vm-deploy/main.yaml` in the Docker container, you would run `./ansible-shell ansible-playbook --ask-vault-pass playbooks/nixos-proxmox-vm-deploy/main.yaml` instead.