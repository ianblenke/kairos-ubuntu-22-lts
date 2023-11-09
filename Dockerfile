#FROM quay.io/kairos/framework:master_fips-systemd as kairos-base
FROM quay.io/kairos/framework:master_ubuntu-22-lts as kairos-base
#FROM quay.io/kairos/framework:master_ubuntu as kairos-base

# Base ubuntu image ()
FROM ubuntu:jammy as base

FROM quay.io/luet/base:0.35.0 as luet

# Generate os-release file
FROM quay.io/kairos/osbuilder-tools:latest as osbuilder
RUN zypper install -y gettext && zypper clean
RUN mkdir /workspace
COPY --from=base /etc/os-release /workspace/os-release
# You should change the following values according to your own versioning and other details
RUN OS_NAME=kairos-core-ubuntu-fips \
  OS_VERSION=v2.4.1 \
  OS_ID="kairos" \
  OS_NAME=kairos-ubuntu-22-lts \
  BUG_REPORT_URL="https://github.com/ianblenke/kairos-ubuntu-22-lts/issues" \
  HOME_URL="https://github.com/ianblenke/kairos-ubuntu-22-lts" \
  OS_REPO="docker.io/ianblenke/kairos-ubuntu-22-lts" \
  OS_LABEL="latest" \
  GITHUB_REPO="ianblenke/kairos-ubuntu-22-lts" \
  VARIANT="nucleus" \
  FLAVOR="ubuntu" \
  /update-os-release.sh

# Build the custom ubuntu image
FROM base

# Don't get asked while running apt commands
ENV DEBIAN_FRONTEND=noninteractive

### THIS comes from the Ubuntu documentation: https://canonical-ubuntu-pro-client.readthedocs-hosted.com/en/latest/tutorials/create_a_fips_docker_image.html
### I've just added "linux-image-fips" in the package list
#RUN --mount=type=secret,id=pro-attach-config \
#    apt-get update \
#    && apt-get install --no-install-recommends -y ubuntu-advantage-tools ca-certificates \
#    && pro attach --attach-config /run/secrets/pro-attach-config \
#    && apt-get upgrade -y \
#    && apt-get install -y openssl libssl1.1 libssl1.1-hmac libgcrypt20 libgcrypt20-hmac strongswan strongswan-hmac openssh-client openssh-server linux-image-fips \
#    && pro detach --assume-yes


## Kairos setup
## From documentation: https://kairos.io/docs/reference/build-from-scratch/
RUN mkdir -p /run/lock
RUN mkdir -p /usr/libexec
RUN touch /usr/libexec/.keep

## Kairos required packages
## See: https://github.com/kairos-io/kairos/blob/master/images/Dockerfile.ubuntu-20-lts
RUN apt-get update \
 && apt-get install -y --no-install-recommends \
    avahi-daemon \
    build-essential \
    conntrack \
    console-data \
    coreutils \
    cryptsetup \
    curl \
    debianutils \
    dmsetup \
    dosfstools \
    dracut \
    dracut-network \
    dracut-config-generic \
    dracut-core \
    dracut-live \
    dracut-squash \
    e2fsprogs \
    efibootmgr \
    file \
    fuse \
    gawk \
    gdisk \
    git \
    gpg \
    grub2 \
    grub2-common \
    grub-efi-amd64-bin \
    grub-efi-amd64-signed \
    grub-pc-bin \
    haveged \
    htop \
    iproute2 \
    iptables \
    iputils-ping \
    isc-dhcp-common \
    jq \
    kbd \
    krb5-locales \
    libssl-dev \
    linux-generic-hwe-22.04 \
    lldpd \
    lvm2 \
    make \
    mdadm \
    nano \
    nbd-client \
    ncurses-term \
    neovim \
    networkd-dispatcher \
    nfs-common \
    nvme-cli \
    open-iscsi \
    openssh-server \
    open-vm-tools \
    os-prober \
    packagekit-tools \
    parted \
    patch \
    policykit-1 \
    publicsuffix \
    qemu-guest-agent \
    rsync \
    shared-mime-info \
    smartmontools \
    snapd \
    snmpd \
    squashfs-tools \
    sudo \
    systemd \
    systemd-timesyncd \
    thermald \
    xdg-user-dirs \
    xxd \
    xz-utils \
    zerofree \
    zfsutils-linux \
    zstd \
    && apt-get remove -y unattended-upgrades && apt-get clean \
    && rm -rf /var/lib/apt/lists/*
#    ubuntu-advantage-tools \
#    && apt-get purge --auto-remove -y ubuntu-advantage-tools \
#    busybox \
#    initramfs-tools \

# Copy the Kairos framework files. We use master builds here for fedora. See https://quay.io/repository/kairos/framework?tab=tags for a list
COPY --from=kairos-base / /
# Copy the os-release file to identify the OS
COPY --from=osbuilder /workspace/os-release /etc/os-release

# Activate Kairos services
RUN systemctl enable cos-setup-reconcile.timer && \
          systemctl enable cos-setup-fs.service && \
          systemctl enable cos-setup-boot.service && \
          systemctl enable cos-setup-network.service

### Configuration
### Took from: https://github.com/kairos-io/kairos/blob/master/images/Dockerfile.ubuntu-20-lts
## workaround https://github.com/kairos-io/kairos/issues/949
#COPY dracut-broken-iscsi-ubuntu-20.patch /
#RUN cd /usr/lib/dracut/modules.d/95iscsi && patch < /dracut-broken-iscsi-ubuntu-20.patch && rm -rf /dracut-broken-iscsi-ubuntu-20.patch

COPY dracut.conf /etc/dracut.conf.d/kairos-fips.conf
## CLEANUP
## Installing dracut and fips creates this default packages and symlinks and we dont want that
## We want to fully rebuild and link our initrd
RUN rm -Rf /boot/vmlinuz.old # symlink
RUN rm -Rf /boot/vmlinuz.img.old # symlink
RUN rm -Rf /boot/vmlinuz.img # symlink
RUN rm -Rf /boot/initrd.img.old # symlink to wrong initrd (no immucore, no kairos-agent)
RUN rm -Rf /boot/initrd.img # symlink to wrong initrd (no immucore, no kairos-agent)
RUN rm -Rf /boot/initrd.img-* # wrong initrd (no immucore, no kairos-agent)
RUN rm -Rf /boot/.vmlinuz.hmac # No idea
### Symlink in kernel
### Generate initrd
#RUN update-initramfs -c -k all
### Symlink in initrd
RUN kernel=$(ls /lib/modules | head -n1) \
 && ln -nsf "vmlinuz-${kernel}" /boot/vmlinuz \
 && dracut -v -N -f "/boot/initrd-${kernel}" "${kernel}" \
 && ln -nsf "initrd-${kernel}" /boot/initrd \
 && depmod -a "${kernel}"
RUN rm -rf /boot/initramfs-*

# Fixup sudo perms
RUN chown root:root /usr/bin/sudo && chmod 4755 /usr/bin/sudo

# Symlink kernel HMAC
RUN kernel=$(ls /boot/vmlinuz-* | head -n1) && ln -sf ."${kernel#/boot/}".hmac /boot/.vmlinuz.hmac

# Clear cache
RUN rm -rf /var/cache/* && journalctl --vacuum-size=1K && rm /etc/machine-id && rm /var/lib/dbus/machine-id && rm /etc/hostname

# All of this is probably wrong, but I'm missing documentation here.
COPY --from=luet /usr/bin/luet /usr/bin/luet
COPY framework-profile.yaml /etc/luet/luet.yaml
RUN luet install -y utils/edgevpn utils/k9s utils/nerdctl container/kubectl utils/kube-vip k8s/k3s-systemd
RUN luet database get-all-installed --output /etc/kairos/versions.yaml

# Enable tun module on boot for edgevpn/vpn services
RUN echo "tun" >> /etc/modules

RUN echo 'LANG="en_US.UTF-8"' > /etc/default/locale


