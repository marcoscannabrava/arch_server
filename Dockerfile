FROM archlinux:latest

RUN pacman -Syu --noconfirm base-devel

RUN useradd -m builder && \
    echo 'builder ALL=(ALL) NOPASSWD: ALL' > /etc/sudoers.d/builder

WORKDIR /home/builder/pkg
COPY --chown=builder:builder PKGBUILD home-server.install \
     home-server-setup home-server-add-app home-server-nanoclaw \
     Caddyfile.template index.html \
     cloudflare-ddns cloudflare-ddns.conf.example \
     cloudflare-ddns.service cloudflare-ddns.timer \
     docker-compose@.service ./

USER builder
RUN sudo chown -R builder:builder /home/builder/pkg

CMD ["makepkg", "-s", "--noconfirm"]
