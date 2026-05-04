packer {
  required_plugins {
    qemu = {
      source  = "github.com/hashicorp/qemu"
      version = "~> 1"
    }
    windows-update = {
      version = "v0.18.1"
      source  = "github.com/rgl/windows-update"
    }
    external = {
      version = "> 0.0.2"
      source  = "github.com/joomcode/external"
    }
  }
}

data "external-raw" "virtio" {
  program = [
    "bash", "-c",
    "if [ ! -f virtio-win.iso ]; then wget -nv https://fedorapeople.org/groups/virt/virtio-win/direct-downloads/stable-virtio/virtio-win.iso -O virtio-win.iso ; fi"
  ]
}

source "qemu" "windows_11" {
  boot_command         = ["<wait2s> <wait2s> <wait2s> <wait2s> <wait2s>"]
  boot_wait            = "1s"
  disk_interface       = "virtio"
  disk_size            = "65000"
  efi_boot             = true
  efi_firmware_code    = "/usr/share/OVMF/OVMF_CODE_4M.secboot.fd"
  efi_firmware_vars    = "/usr/share/OVMF/OVMF_VARS_4M.ms.fd"
  floppy_files         = ["Autounattend.xml", "redhat.cer", "scripts/microsoft-updates.ps1", "scripts/openssh.ps1", "scripts/spiceToolsInstall.ps1", "scripts/fixnetwork.ps1", "scripts/power_plan_tune.cmd"]
  format               = "raw"
  headless             = "true"
  iso_checksum         = "a61adeab895ef5a4db436e0a7011c92a2ff17bb0357f58b13bbc4062e535e7b9"
  iso_url              = "https://software-static.download.prss.microsoft.com/dbazure/888969d5-f34g-4e03-ac9d-1f9786c66749/26200.6584.250915-1905.25h2_ge_release_svc_refresh_CLIENTENTERPRISEEVAL_OEMRET_x64FRE_en-us.iso"
  machine_type         = "q35,smm=on,hpet=off"
  output_directory     = "target-qemu"
  qemuargs             = [
      ["-enable-kvm"],
      ["-m", "6144m"],
      ["-smp", "4,sockets=1,cores=4,threads=1"],
      ["-cpu", "host,hv_relaxed,hv_vapic,hv_runtime,hv_time,hv_vpindex,hv_synic,hv_stimer,hv_tlbflush,hv_ipi,hv_frequencies,hv_stimer_direct,hv_xmm_input,hv_spinlocks=0x1fff"],
      ["-global", "kvm-pit.lost_tick_policy=discard"],
      ["-global", "driver=cfi.pflash01,property=secure,value=on"],
      ["-device", "virtio-tablet"],
      ["-cdrom", "virtio-win.iso"]
  ]

  shutdown_command     = "shutdown /s /t 10 /f /d p:4:1 /c \"Packer Shutdown\""
  ssh_private_key_file = "ssh-key"
  ssh_username         = "windows"
  ssh_wait_timeout     = "5h"
  use_default_display  = "true"
  vm_name              = "windows-11"
  vnc_bind_address     = "0.0.0.0"
  vnc_port_max         = "5900"
  vnc_port_min         = "5900"
}

build {
  sources = ["source.qemu.windows_11"]

  provisioner "windows-update" {
    filters = [
      # exclude KB5007651:
      # Update for Windows Security platform - KB5007651 (Version 10.0.29510.1001)
      # NB it can only be applied while the user is logged in.
      "exclude:$_.Title -like '*KB5007651*'",
      "exclude:$_.Title -like '*KB5083769*'",
      "include:$true",
    ]
  }

  provisioner "powershell" {
    scripts = [
      # "scripts/configureRemotingForAnsible.ps1",
      # "scripts/spiceToolsInstall.ps1",
      "scripts/enable-rdp.ps1"
    ]
  }

  provisioner "windows-restart" {}

  provisioner "windows-shell" {
    script = "scripts/disable-auto-logon.bat"
  }

  provisioner "powershell" {
    scripts = [
      "scripts/fix.ps1",
      "scripts/Install-CloudBaseInit.ps1",
      "scripts/cleanup.ps1",
      "scripts/remove-recovery-partition.ps1",
      "scripts/shrink-filesystem.ps1",
      "scripts/sysprep.ps1"
    ]
  }

post-processor "shell-local" {
    inline_shebang = "/bin/bash -e"
    inline = [
      <<-EOF
        set -euo pipefail

        IMG="target-qemu/windows-server-2025"

        # Print initial state for debugging
        parted -s "$IMG" unit b print free

        # Extract end bytes of partition 3
        END=$(parted -sm "$IMG" unit b print | grep '^3:' | cut -d: -f3)
        END_BYTES=$${END%B}

        # Align to 1 MiB (1048576 bytes)
        ALIGN=1048576

        # Calculate new size: round up to nearest 1 MiB, plus 1 extra MiB for the GPT footer
        NEW_SIZE=$(( (END_BYTES + ALIGN + ALIGN - 1) / ALIGN * ALIGN ))

        echo "Partition end: $${END_BYTES}B"
        echo "New image size aligned to 1MiB: $${NEW_SIZE}B"

        # Execute resize and GPT repair
        qemu-img resize -f raw --shrink "$IMG" "$NEW_SIZE"
        sgdisk --move-second-header "$IMG"

        # Convert to qcow2
        qemu-img convert -f raw -O qcow2 "$IMG" "$IMG.qcow2"
      EOF
    ]
  }
}
