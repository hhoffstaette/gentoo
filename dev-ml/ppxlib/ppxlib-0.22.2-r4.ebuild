# Copyright 1999-2024 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

inherit dune

# Note that new "major" versions may change which OCaml version they support
# See:
# https://github.com/ocaml-ppx/ppxlib/issues/243
# https://github.com/ocaml-ppx/ppxlib/issues/232

DESCRIPTION="Base library and tools for ppx rewriters"
HOMEPAGE="https://github.com/ocaml-ppx/ppxlib"
SRC_URI="https://github.com/ocaml-ppx/ppxlib/archive/${PV}.tar.gz -> ${P}.tar.gz"

LICENSE="Apache-2.0"
SLOT="0/${PV}"
KEYWORDS="amd64 arm arm64 ~ppc ppc64 x86"
IUSE="+ocamlopt test"
RESTRICT="!test? ( test )"

RDEPEND="
	>=dev-ml/ocaml-compiler-libs-0.11.0:=[ocamlopt?]
	>=dev-ml/ocaml-migrate-parsetree-2.2.0:=[ocamlopt?]
	dev-ml/sexplib0:=[ocamlopt?]
	dev-ml/stdlib-shims:=[ocamlopt?]
	>=dev-ml/ppx_derivers-1.2.1:=[ocamlopt?]
	<dev-lang/ocaml-5
"
DEPEND="${RDEPEND}
	test? (
		dev-ml/findlib:=[ocamlopt?]
		>=dev-ml/base-0.11.0:=[ocamlopt?]
		dev-ml/cinaps:=
		dev-ml/re:=
		>=dev-ml/stdio-0.11.0:=[ocamlopt?]
	)
"
BDEPEND=">=dev-ml/dune-2.8"

src_install() {
	dune_src_install

	# Clashes with dev-libs/nss[utils], accidentally installed upstream
	# https://github.com/ocaml-ppx/ppxlib/issues/224
	rm "${ED}"/usr/bin/pp || die
}
