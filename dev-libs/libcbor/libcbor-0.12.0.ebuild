# Copyright 2020-2025 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

PYTHON_COMPAT=( python3_{11..13} )
inherit python-any-r1 cmake

DESCRIPTION="CBOR protocol implementation for C and others"
HOMEPAGE="https://github.com/pjk/libcbor"
SRC_URI="https://github.com/PJK/${PN}/archive/v${PV}.tar.gz -> ${P}.tar.gz"

LICENSE="MIT"
SLOT="0/$(ver_cut 1-2)"
KEYWORDS="~alpha amd64 arm arm64 ~hppa ~loong ~m68k ~mips ppc ppc64 ~riscv ~s390 sparc x86"
IUSE="doc test"

BDEPEND="
	doc? (
		$(python_gen_any_dep '
			dev-python/sphinx[${PYTHON_USEDEP}]
			dev-python/sphinx-rtd-theme[${PYTHON_USEDEP}]
			dev-python/breathe[${PYTHON_USEDEP}]
		')
	)
	test? ( dev-util/cmocka )
"

RESTRICT="!test? ( test )"

PATCHES=(
	"${FILESDIR}"/${P}-cmake-4.patch
)

python_check_deps() {
	python_has_version \
		"dev-python/sphinx[${PYTHON_USEDEP}]" \
		"dev-python/sphinx-rtd-theme[${PYTHON_USEDEP}]" \
		"dev-python/breathe[${PYTHON_USEDEP}]"
}

pkg_setup() {
	use doc && python-any-r1_pkg_setup
}

src_configure() {
	local mycmakeargs=(
		-DCMAKE_BUILD_TYPE=Release
		-DWITH_TESTS=$(usex test)
		-Wno-dev
	)

	cmake_src_configure
}

src_compile() {
	cmake_src_compile

	if use doc; then
		mkdir -p doc/build || die
		emake -C doc -j1 html man
	fi
}

src_install() {
	cmake_src_install

	if use doc; then
		dodoc -r "${S}"/doc/build/html
		doman "${S}"/doc/build/man/*.?
	fi
}
