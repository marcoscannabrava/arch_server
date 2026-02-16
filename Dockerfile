FROM archlinux:latest

RUN pacman -Syu --noconfirm base-devel

RUN useradd -m builder && \
    echo 'builder ALL=(ALL) NOPASSWD: ALL' > /etc/sudoers.d/builder

WORKDIR /home/builder/pkg
COPY --chown=builder:builder PKGBUILD home-server.install home-server-setup ./

USER builder
RUN sudo chown -R builder:builder /home/builder/pkg

CMD ["makepkg", "-s", "--noconfirm"]
