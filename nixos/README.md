# NixOS Kubernetes Node Setup

This runbook installs a Proxmox VM as a NixOS k3s node from the NixOS ISO.

## 1. Provision The VM

Example Terraform shape:

```hcl
module "k8s" {
  source = "../../modules/proxmox_vm"

  node_name    = local.node_name
  datastore_id = local.local_datastore_id

  vm_id       = 501
  template_id = local.nixos_template_id_26_05
  vm_name     = "home-cp-1"

  cpu_cores = 4
  memory    = 8192

  networks    = []
  nameservers = []

  disk_size = 4 # installer ISO / bootstrap disk
  extra_disks = [
    { interface = "virtio1", size = 128 }, # OS disk
    { interface = "virtio2", size = 256 }  # local PV disk
  ]

  cloud_init_data = ""
}
```

Expected disks from the NixOS ISO:

```text
vda = NixOS ISO
vdb = OS disk
vdc = local PV disk
```

Only partition and format `vdb` during OS installation. Leave `vdc` untouched until local PV setup.

## 2. Boot The Installer

Open the VM console from Proxmox and boot into the NixOS ISO.

Check the disk layout:

```bash
lsblk -f
```

Check boot mode:

```bash
test -d /sys/firmware/efi && echo UEFI || echo BIOS
```

This configuration uses `systemd-boot`, so the VM should use Proxmox `OVMF (UEFI)` with an EFI disk.

## 3. Partition The OS Disk

Warning: these commands destroy data on `/dev/vdb`.

```bash
sudo parted /dev/vdb -- mklabel gpt
sudo parted /dev/vdb -- mkpart ESP fat32 1MiB 513MiB
sudo parted /dev/vdb -- set 1 esp on
sudo parted /dev/vdb -- mkpart primary ext4 513MiB 100%
```

Format the partitions:

```bash
sudo mkfs.fat -F 32 -n NIXBOOT /dev/vdb1
sudo mkfs.ext4 -L NIXROOT /dev/vdb2
```

Mount them:

```bash
sudo mount /dev/disk/by-label/NIXROOT /mnt
sudo mkdir -p /mnt/boot
sudo mount /dev/disk/by-label/NIXBOOT /mnt/boot
```

## 4. Generate Hardware Config

Enable flakes in the live environment:

```bash
mkdir -p ~/.config/nix
printf 'experimental-features = nix-command flakes\n' > ~/.config/nix/nix.conf
```

Clone this repository:

```bash
git clone https://github.com/fudoge/homelab.git ~/homelab
cd ~/homelab/nixos
```

Generate the target node hardware config into the flake:

```bash
sudo nixos-generate-config --root /mnt
cp /mnt/etc/nixos/hardware-configuration.nix hosts/cp-1/hardware-configuration.nix
```

Make sure `hosts/cp-1/configuration.nix` imports it:

```nix
imports = [
  ./hardware-configuration.nix
];
```

The generated hardware config should contain:

```nix
fileSystems."/" = {
  device = "/dev/disk/by-label/NIXROOT";
  fsType = "ext4";
};

fileSystems."/boot" = {
  device = "/dev/disk/by-label/NIXBOOT";
  fsType = "vfat";
};

nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
```

## 5. Install NixOS

From `~/homelab/nixos`:

```bash
sudo nixos-install --flake '.#cp-1'
```

Set the root password when prompted.

After installation, shut down or reboot. In Proxmox:

1. Remove the NixOS ISO from the CD/DVD drive.
2. Set boot order so the OS disk is first.
3. Boot the VM again.

## 6. Local PV Disk

Use the separate disk, expected as `/dev/vdc`, after the OS is installed but before the first rebuild. The NixOS config mounts this disk by the `LOCALPV` filesystem label.

Warning: these commands destroy data on `/dev/vdc`.

```bash
sudo parted /dev/vdc -- mklabel gpt
sudo parted /dev/vdc -- mkpart primary ext4 0% 100%
sudo mkfs.ext4 -L LOCALPV /dev/vdc1
```

Check that the label is visible:

```bash
lsblk -f
```

## 7. First Rebuild

After booting into the installed system and preparing the local PV disk:

```bash
git clone https://github.com/fudoge/homelab.git ~/homelab
cd ~/homelab/nixos
```

Then rebuild:

```bash
sudo nixos-rebuild switch --flake '.#cp-1'
```

Keep the flake selector quoted. Without quotes, some shells can treat `#cp-1` as a comment.

## 8. Bootstrap Cluster Access

Use the local k3s kubeconfig only for initial bootstrap access. After Flux reconciles the Tailscale operator, use the Tailscale API server proxy instead.

On the node, for bootstrap only:

```bash
mkdir -p ~/.kube
sudo cp /etc/rancher/k3s/k3s.yaml ~/.kube/config
sudo chown $(id -u):$(id -g) ~/.kube/config
```

If this temporary kubeconfig needs to be used from another machine, update the API server address to the node's LAN DNS name or static LAN IP:

```bash
sed -i 's/127.0.0.1/home-cp-1/' ~/.kube/config
```

Flux needs the SOPS age private key once before it can decrypt encrypted Secrets from Git:

```bash
kubectl -n flux-system create secret generic sops-age \
  --from-file=age.agekey="$HOME/.config/sops/age/keys.txt"
```

Grant the Tailscale API server proxy identity admin access once. The user value must match the Kubernetes user returned through the proxy; for this tailnet it is `fudoge@github`.

```bash
kubectl create clusterrolebinding tailscale-admin-fudoge \
  --clusterrole=cluster-admin \
  --user='fudoge@github'
```

If the binding already exists, apply it idempotently:

```bash
kubectl create clusterrolebinding tailscale-admin-fudoge \
  --clusterrole=cluster-admin \
  --user='fudoge@github' \
  --dry-run=client -o yaml | kubectl apply -f -
```

## 9. Tailscale Kubeconfig

After Flux installs the Tailscale operator with `apiServerProxyConfig.mode: "true"`, configure the normal kubeconfig from a Tailscale client:

```bash
tailscale configure kubeconfig tailscale-operator
```

Test it:

```bash
kubectl get nodes
```

The generated context uses the operator's API server proxy over the tailnet. Kubernetes RBAC still applies to the Tailscale identity that reaches the proxy.
