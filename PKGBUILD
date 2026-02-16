# Maintainer: Marcos
pkgname=home-server
pkgver=1.0.0
pkgrel=1
pkgdesc="Meta-package for a simple home server with Caddy, Docker, and SSH"
arch=('any')
url="https://github.com/marcos/home-server"
license=('MIT')
depends=(
  'caddy'
  'docker'
  'docker-compose'
  'openssh'
  'nodejs'
  'npm'
)
install=home-server.install
source=('home-server-setup')
sha256sums=('SKIP')

package() {
  install -Dm755 "$srcdir/home-server-setup" "$pkgdir/usr/bin/home-server-setup"
}
