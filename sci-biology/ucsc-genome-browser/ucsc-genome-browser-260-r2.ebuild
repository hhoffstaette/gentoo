# Copyright 1999-2024 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

WEBAPP_MANUAL_SLOT="yes"
# TODO: use WEBAPP_OPTIONAL?
inherit toolchain-funcs flag-o-matic webapp

DESCRIPTION="The UCSC genome browser suite, also known as Jim Kent's library and GoldenPath"
HOMEPAGE="http://genome.ucsc.edu/"
SRC_URI="http://hgdownload.cse.ucsc.edu/admin/jksrc.v${PV}.zip"
S="${WORKDIR}/kent"

LICENSE="blat"
SLOT="0"
KEYWORDS="~amd64 ~x86"
IUSE="+mysql +server static-libs"
REQUIRED_USE="server? ( mysql )"

# TODO: test with other webservers
RDEPEND="
	dev-libs/openssl:=
	media-libs/libpng:=
	!<sci-biology/ucsc-genome-browser-223
	mysql? ( dev-db/mysql-connector-c:= )
	server? ( virtual/httpd-cgi )
"
DEPEND="${RDEPEND}"
BDEPEND="
	app-alternatives/cpio
	app-arch/unzip
"

pkg_setup() {
	use server && webapp_pkg_setup
}

src_prepare() {
	default

	use server && webapp_src_preinst

	# bug #708064
	append-flags -fcommon
	# bug #831491, bug #919200, bug #921261
	append-flags -std=gnu89

	sed \
		-e 's/-Werror//' \
		-e "/COPT/s:=.*$:=${LDFLAGS}:g" \
		-e "s/CC=gcc/CC=$(tc-getCC) ${CFLAGS}/" \
		-e 's:${CC} ${COPT} ${CFLAGS}:${CC} ${CFLAGS}:g' \
		-i src/inc/common.mk src/hg/lib/makefile || die
	find -name makefile -or -name cgi_build_rules.mk \
		| xargs sed -i \
			-e 's/-${USER}//g' \
			-e 's/-$(USER)//g' \
			-e 's:-O2::g' \
			-e 's:-ggdb::g' \
			-e 's:-pipe::g' || die
	sed \
		-e 's:${DISTDIR}${BINDIR}:${BINDIR}:g' \
		-i src/hg/genePredToMafFrames/makefile || die
}

src_compile() {
	export MACHTYPE=${MACHTYPE/-*/} \
		BINDIR="${WORKDIR}/destdir/opt/${PN}/bin" \
		SCRIPTS="${WORKDIR}/destdir/opt/${PN}/cluster/scripts" \
		ENCODE_PIPELINE_BIN="${WORKDIR}/destdir/opt/${PN}/cluster/data/encode/pipeline/bin" \
		PATH="${BINDIR}:${PATH}" \
		STRIP="echo 'skipping strip' "

	export MYSQLLIBS="none" MYSQLINC="none" DOCUMENTROOT="none" CGI_BIN="none"

	# TODO: use pkg-config here
	use mysql && export MYSQLLIBS="-L${ESYSROOT}/usr/$(get_libdir)/mysql/ -lmysqlclient -lz -lssl" \
		MYSQLINC="${ESYSROOT}/usr/include/mysql"

	use server && export DOCUMENTROOT="${WORKDIR}/destdir/${MY_HTDOCSDIR}" \
		CGI_BIN="${WORKDIR}/destdir/${MY_HTDOCSDIR}/cgi-bin"

	mkdir -p "${BINDIR}" "${SCRIPTS}" "${ENCODE_PIPELINE_BIN}" || die
	use server && mkdir -p "${CGI_BIN}" "${DOCUMENTROOT}"

	emake -C src clean
	emake -C src/lib
	emake -C src/jkOwnLib
	emake -C src/utils/stringify
	emake -C src blatSuite
	if use mysql; then
		emake -j1 -C src/hg utils
		emake -j1 -C src utils
		emake -C src libs userApps
		if use server; then
			emake -j1 -C src/hg
			emake -j1 -C src
		fi
	fi
}

src_install() {
	use server && webapp_src_preinst
	cp -ad "${WORKDIR}"/destdir/* "${D}" || die
	use static-libs && dolib.a src/lib/${MACHTYPE/-*/}/*.a
	echo "PATH=${EPREFIX}/opt/${PN}/bin" > "${S}/98${PN}"
	doenvd "${S}/98${PN}"

	use server && webapp_postinst_txt en src/product/README.QuickStart
	use server && webapp_src_install

	insinto "/usr/include/${PN}"
	doins src/inc/*.h
	insinto "/usr/share/${PN}"
	doins -r src/product
	keepdir "/usr/share/doc/${PF}"
	find -name 'README*' -or -name '*.doc' | grep -v test | cpio -padv "${ED}/usr/share/doc/${PF}" || die
}

pkg_postinst() {
	use server && webapp_pkg_postinst
}
