# Base image is Fedora 43 (not the sha256-pinned 42): TUNA mirrors Fedora under
# releases/43 (200) but not releases/42 (404), so the pinned 42 can't dnf-install
# from the China mirror. 43 matches the tpl-gentoo-builder host too. Pulled via
# the registry mirror (hub.infra.plz.ac) configured in registries.conf.
FROM docker.io/library/fedora:43
LABEL org.opencontainers.image.authors="Frédéric Pierret <frederic@invisiblethingslab.com>"

# China mirror: point the image's dnf at TUNA so the big install below isn't
# fetched over the wall (default metalink -> mirrors.fedoraproject.org is slow
# from CN and made the build time out). ARG so it can be overridden at build time.
ARG FEDORA_MIRROR=https://mirrors.tuna.tsinghua.edu.cn/fedora
RUN for r in /etc/yum.repos.d/fedora.repo /etc/yum.repos.d/fedora-updates.repo; do \
        [ -f "$r" ] && sed -i \
            -e 's|^metalink=|#metalink=|g' \
            -e "s|^#\?baseurl=http://download.example/pub/fedora/linux|baseurl=${FEDORA_MIRROR}|g" \
            "$r"; \
    done

# Install dependencies for Qubes Builder
RUN dnf -y update && \
    dnf install -y \
        arch-install-scripts \
        archlinux-keyring \
        asciidoc \
        createrepo_c \
        debian-keyring \
        debootstrap \
        devscripts \
        dnf-plugins-core \
        dosfstools \
        dpkg-dev \
        e2fsprogs \
        git \
        hostname \
        m4 \
        mock \
        pacman \
        pbuilder \
        perl-Digest-MD5 \
        perl-Digest-SHA \
        psmisc \
        python3-debian \
        python3-jinja2-cli \
        python3-pyyaml \
        python3-sh \
        pykickstart \
        reprepro \
        rpm-build \
        rpmdevtools \
        rsync  \
        systemd-udev \
        tree \
        wget \
        which \
        zstd \
    && dnf clean all

# Install devtools for Archlinux
RUN git clone -n https://gitlab.archlinux.org/fepitre/devtools && \
	cd devtools && \
	git checkout f91a1ac64d96a7cb38dc581eb4bd2ba0118d234c && \
	make install DESTDIR=/ PREFIX=/usr/local && \
	ln -s /usr/local/bin/archbuild /usr/local/bin/qubes-x86_64-build

# Create build user
RUN useradd -m user
RUN usermod -aG wheel user && echo '%wheel ALL=(ALL) NOPASSWD: ALL' > /etc/sudoers.d/wheel

# Create needed folders
RUN mkdir /builder /builder/plugins /builder/build /builder/distfiles /builder/cache /builder/repository /builder/sources
RUN mkdir -p /builder/cache/mock
RUN chown -R user /builder

USER user
