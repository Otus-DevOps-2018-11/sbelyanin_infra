# sbelyanin_infra

## ДЗ №9






 packer build -var-file=packer/variables.json packer/db.json
 Build 'googlecompute' finished.

==> Builds finished. The artifacts of successful builds are:
--> googlecompute: A disk image was created: reddit-db-1549218017


 packer build -var-file=packer/variables.json packer/app.json
Build 'googlecompute' finished.

==> Builds finished. The artifacts of successful builds are:
--> googlecompute: A disk image was created: reddit-app-1549218393

terraform apply
Apply complete! Resources: 6 added, 0 changed, 0 destroyed.

./inventory.py --refresh-cache

ansible-playbook site.yml --check
reddit-app-0               : ok=9    changed=7    unreachable=0    failed=0
reddit-db-0                : ok=3    changed=2    unreachable=0    failed=0


ansible-playbook site.yml
reddit-app-0               : ok=9    changed=7    unreachable=0    failed=0
reddit-db-0                : ok=3    changed=2    unreachable=0    failed=0


<details><summary>содержимое</summary><p>

```bash

```
</p></details>
