# Automated server provisioning

## Development

Use `vagrant up` to start a testing VM (requires virtualbox and vagrant).

Run the playbook to provision the test VM.

    ansible-playbook -i hosts.development site.yml --private-key=~/.vagrant.d/insecure_private_key

## Production deploy

    ansible-playbook -i hosts.production site.yml
