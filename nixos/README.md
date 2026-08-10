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

## 6. First Rebuild

After booting into the installed system:

```bash
git clone https://github.com/fudoge/homelab.git ~/homelab
cd ~/homelab/nixos
```

If the local PV disk is not formatted and mounted yet, temporarily comment out any `LOCALPV` filesystem entry before rebuilding:

```nix
# fileSystems."/var/lib/rancher/k3s/storage" = {
#   device = "/dev/disk/by-label/LOCALPV";
#   fsType = "ext4";
# };
```

Then rebuild:

```bash
sudo nixos-rebuild switch --flake '.#cp-1'
```

Keep the flake selector quoted. Without quotes, some shells can treat `#cp-1` as a comment.

## 7. Tailscale

Bring the node online:

```bash
sudo tailscale up
```

Log in through the URL printed by Tailscale.

## 8. Kubeconfig

On the node:

```bash
mkdir -p ~/.kube
sudo cp /etc/rancher/k3s/k3s.yaml ~/.kube/config
sudo chown $(id -u):$(id -g) ~/.kube/config
```

Update the API server address in the copied kubeconfig if needed:

```bash
sed -i 's/127.0.0.1/home-cp-1.tail274d3c.ts.net/' ~/.kube/config
```

Copy it to a laptop:

```bash
scp home-cp-1.tail274d3c.ts.net:/home/chaewoon/.kube/config ~/.kube/config.home-cp-1
```

Test it:

```bash
KUBECONFIG=~/.kube/config.home-cp-1 kubectl get nodes
```

Optional merge:

```bash
KUBECONFIG=~/.kube/config:~/.kube/config.home-cp-1 kubectl config view --merge --flatten > ~/.kube/config.merged
mv ~/.kube/config.merged ~/.kube/config
```

## 9. Local PV Disk

Use the separate disk, expected as `/dev/vdc`, after the OS is installed.

Example:

```bash
sudo parted /dev/vdc -- mklabel gpt
sudo parted /dev/vdc -- mkpart primary ext4 0% 100%
sudo mkfs.ext4 -L LOCALPV /dev/vdc1
```

Then mount it declaratively in NixOS, for example:

```nix
fileSystems."/var/lib/rancher/k3s/storage" = {
  device = "/dev/disk/by-label/LOCALPV";
  fsType = "ext4";
};
```

Adjust the mount path to match the storage class or local-path-provisioner configuration.
