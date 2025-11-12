# saphnet-ansible-playbook
The Ansible playbook for the Saphnet Homelab/Home Server

Useful commands:
- `./ansible-shell.sh [any command]`
- `ansible-playbook --ask-vault-pass playbooks/nixos-proxmox-vm-deploy/main.yaml -vvvv -e "target_vm_name=control_server_main"`
- `ansible-playbook --vault-id control-server@prompt --vault-id proxmox@prompt playbooks/nixos-proxmox-vm-deploy/main.yaml -vvvv`
- `ansible-vault encrypt --vault-id control-server@prompt secrets/control-server.yaml`

TODO: Write documentation