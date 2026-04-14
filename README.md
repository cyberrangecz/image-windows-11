# Windows 11 Base image

This repo contains Packer files for building Windows 11 amd64 base image for QEMU/OpenStack.

SSH and WinRM is enabled, SSH login using password is disabled.

## Image for QEMU/OpenStack

For building this image for QEMU locally, additional [iso image with Windows drivers for QEMU](https://fedorapeople.org/groups/virt/virtio-win/direct-downloads/stable-virtio/virtio-win.iso) must be downloaded.
Use this command to download it: `wget -nv -nc https://fedorapeople.org/groups/virt/virtio-win/direct-downloads/stable-virtio/virtio-win.iso -O virtio-win.iso`.

There is one admin user account:

*  `windows` with password set to random upon startup by [cloudbase-init](https://cloudbase-init.readthedocs.io/en/latest/intro.html) unless password is provided via OpenStack metadata `admin_pass`

## How to build

For information how to build this image see [wiki](https://github.com/cyberrangecz/images-wiki).

## License

This project is licensed under the [MIT License](LICENSE).

## Acknowledgements

<table>
  <tr>
    <td><img src="figures/EU.jpg" alt="EU emblem"/></td>
    <td>
This software and accompanying documentation is part of a [project](https://cybersec4europe.eu) that has received funding from the European Union’s Horizon 2020 research and innovation programme under grant agreement No. 830929.
</td>
  </tr>
  <tr>
      <td><img src="figures/TACR.png" alt="TACR logo"/></td>
      <td>This software was developed with the support of the Technology Agency of the Czech Republic (TA ČR) from the National Centres of Competence programme (project identification TN01000077 – [National Centre of Competence in Cybersecurity](https://nc3.cz/)). 
      </td>
  </tr>
 </table>
