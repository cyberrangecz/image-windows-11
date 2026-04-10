packer {
  required_plugins {
    qemu = {
      source  = "github.com/hashicorp/qemu"
      version = "~> 1"
    }
    windows-update = {
      version = "0.17.3"
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
  boot_wait            = "10s"
  disk_interface       = "virtio"
  disk_size            = "64000"
  floppy_files         = ["Autounattend.xml", "redhat.cer", "scripts/microsoft-updates.ps1", "scripts/openssh.ps1", "scripts/configureRemotingForAnsible.ps1"]
  format               = "raw"
  headless             = "true"
  iso_checksum         = "a61adeab895ef5a4db436e0a7011c92a2ff17bb0357f58b13bbc4062e535e7b9"
  iso_url              = "https://software-static.download.prss.microsoft.com/dbazure/888969d5-f34g-4e03-ac9d-1f9786c66749/26200.6584.250915-1905.25h2_ge_release_svc_refresh_CLIENTENTERPRISEEVAL_OEMRET_x64FRE_en-us.iso"
  output_directory     = "target-qemu"

qemuargs = [
    ["-m", "6144m"],
    ["-smp", "4,sockets=1,cores=4,threads=1"],
    # CPU: host passthrough + the "Hyper-V" secret sauce
    ["-cpu", "host,hv_relaxed,hv_vapic,hv_spinlocks=0x1fff,hv_vpindex,hv_synic,hv_stimer,hv_stimer_direct,hv_reset,hv_frequencies,hv_tlbflush,hv_ipi,hv_runtime,hv_time,kvm=off"],
    # Timers: Disable the "noisy" ones and use hardware clocks
    ["-rtc", "base=localtime,driftfix=slew"],
    ["-global", "kvm-pit.lost_tick_policy=delay"],
    ["-no-hpet"],
    # Modern Machine Type (use q35 if possible for Windows 11)
    ["-machine", "q35,accel=kvm,usb=off,dump-guest-core=off"],
    # Input & Drivers
    ["-device", "virtio-tablet-pci"],
    ["-device", "virtio-serial-pci"],
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

  provisioner "windows-update" {}

  provisioner "file" {
    destination = "C:/Windows/Temp/"
    source      = "scripts/spice-guest-tools.exe"
  }

  provisioner "powershell" {
    scripts = [
      # "scripts/configureRemotingForAnsible.ps1",
      "scripts/spiceToolsInstall.ps1",
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
      "scripts/shrink-filesystem.ps1",
      "scripts/sysprep.ps1"
    ]
  }

  post-processor "shell-local" {
    inline = [
      "parted -s target-qemu/* print free",
      "NEW_SIZE=$(parted -sm target-qemu/* unit b print free | grep free | awk -F ':' '{print $2}' | sort -rh | head -n 1)",
      "qemu-img resize -f raw --shrink target-qemu/* $NEW_SIZE",
      "qemu-img convert -f raw -O qcow2 target-qemu/windows-11 target-qemu/windows-11.qcow2"
    ]
  }
}
