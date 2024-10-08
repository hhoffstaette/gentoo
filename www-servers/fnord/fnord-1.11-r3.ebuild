# Copyright 1999-2024 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

inherit flag-o-matic toolchain-funcs

DESCRIPTION="Yet another small httpd"
HOMEPAGE="https://www.fefe.de/fnord/"
SRC_URI="https://www.fefe.de/fnord/${P}.tar.bz2"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~amd64 ~hppa ~ppc ~riscv sparc x86"
IUSE="auth"

RDEPEND="
	acct-group/nofiles
	acct-user/fnord
	acct-user/fnordlog
	sys-apps/ucspi-tcp
	virtual/daemontools
"

DOCS=( TODO README README.auth SPEED CHANGES )

PATCHES=(
	"${FILESDIR}/${PN}"-1.10-gentoo.diff
	"${FILESDIR}/${PN}"-1.11-clang-16-build-fix.patch
)

src_compile() {
	# Fix for bug #45716
	use sparc && replace-sparc64-flags
	use auth && append-flags -DAUTH

	emake DIET="" CC=$(tc-getCC) CFLAGS="${CFLAGS}" LDFLAGS="${LDFLAGS}"
}

src_install() {
	dobin fnord-conf fnord
	einstalldocs
}
