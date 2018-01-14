#!/bin/bash
###############################################################################
# Copyright © 2016 Stéphane Veyret stephane_DOT_veyret_AT_neptura_DOT_org
#
# This file is part of MisybaG.
#
# MisybaG is free software: you can redistribute it and/or modify it under the
# terms of the GNU General Public License as published by the Free Software
# Foundation, either version 3 of the License, or (at your option) any later
# version.
#
# MisybaG is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
# A PARTICULAR PURPOSE. See the GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License along with
# MisybaG.  If not, see <http://www.gnu.org/licenses/>.
###############################################################################

# Load configuration
: ${MISYBAG_CONFIG_DIR:="/usr/share/MisybaG"}
source gettext.sh
export TEXTDOMAIN=MisybaG

############
# Display help on syntax
# Parameters:
#  1. The name of this script.
help() {
	local msbg_name=${1}
	echo -e $(eval_gettext "Usage: \${msbg_name} [new|sys-install|update] [parameters]")
	echo
	echo -e $(eval_gettext "\${msbg_name} new profile_name [dir_name]")
	echo -e "  "$(eval_gettext "Create a new MisybaG project using given profile_name in dir_name.")
	echo -e "  "$(eval_gettext "profile_name is a MisybaG profile name, i.e. the path of the sub-directory of:")
	echo "${MISYBAG_CONFIG_DIR}/profiles/MisybaG/"
	echo -e "  "$(eval_gettext "dir_name is the name of directory where new project will be created. The\\ndirectory is created if it does not exist. New project is created in current\\ndirectory if none given.")
	echo
	echo -e $(eval_gettext "\${msbg_name} sys-install")
	echo -e "  "$(eval_gettext "Install the full target system. This will delete the current content on the\\ntarget.")
	echo
	echo -e $(eval_gettext "\${msbg_name} update")
	echo -e "  "$(eval_gettext "Update the target system, using project configuration.")
}

############
# Create the make.conf file.
# Parameters:
#  1. The CHOST.
createMakeConf() {
	# Extract or calculate variables
	local cflags=$(emerge --info | grep '^CFLAGS\s*=' | sed 's/CFLAGS\s*=\s*"\?\([^"]*\)"\?/\1/')
	local chost="${1}"
	local all_arch=""
	local all_cbuild=""
	if [[ ! -z "${SYSROOT}" ]]; then
		all_arch="ARCH=\""$(grep '^ARCH=' "${SYSROOT}/etc/portage/make.conf" | sed 's/ARCH\s*=\s*"\?\([^"]*\)"\?/\1/')"\""
		all_cbuild="CBUILD=\""$(grep '^CBUILD=' "${SYSROOT}/etc/portage/make.conf" | sed 's/CBUILD\s*=\s*"\?\([^"]*\)"\?/\1/')"\""
	fi
	local makeopts="-j$(nproc)"

	# Create make.conf
	cat >"${PORTAGE_CONFIGROOT}/etc/portage/make.conf" <<-EOF
		CFLAGS="${cflags}"
		CXXFLAGS="\${CFLAGS}"

		${all_arch}
		${all_cbuild}
		CHOST="${chost}"
		MAKEOPTS="${makeopts}"

		USE=""
		LINGUAS=""
		L10N=""

		FEATURES="nodoc noinfo"
		EMERGE_DEFAULT_OPTS="--verbose"
	EOF
}

############
# Create the new project.
# Parameters:
#  1. The path to the profile.
#  2. (optional) The directory where project must be created.
new() {
	# Prepare function environment
	if [[ -z "${1}" ]]; then
		echo -e $(eval_gettext "Missing profile") >&2
		exit 1
	fi
	local profile_dir="${MISYBAG_CONFIG_DIR}/profiles/MisybaG/${1#/}"
	if [[ ! -d ${profile_dir} ]]; then
		echo -e $(eval_gettext "Profile directory \${profile_dir} does not exist")
		exit 1
	fi
	profile_dir="$(cd "${profile_dir}"; pwd)"
	local project_dir=${2:-${PWD}}
	[[ -d "${project_dir}" ]] || mkdir -p "${project_dir}" || exit 1
	project_dir="$(cd "${project_dir}"; pwd)"

	# Prepare layout
	cp -dnR "${MISYBAG_CONFIG_DIR}"/skel/* "${project_dir}"/ || exit 1
	[[ -f "${project_dir}"/_layout/etc/hostname ]] || echo "$(basename "${project_dir}")" >"${project_dir}"/_layout/etc/hostname

	# Prepare configuration
	export PORTAGE_CONFIGROOT="${project_dir}"/_portage
	mkdir -p "${PORTAGE_CONFIGROOT}"/etc/portage/{repos.conf,package.{accept_keywords,env,license,mask,properties,unmask,use},patches} \
		|| exit 1
	ln -s "${profile_dir}" "${PORTAGE_CONFIGROOT}"/etc/portage/make.profile
	local chost=$(emerge --info | grep '^CHOST\s*=' | sed 's/CHOST\s*=\s*"\?\([^"]*\)"\?/\1/')
	export SYSROOT=/usr/"${chost}"
	if [[ ! -d "${SYSROOT}" ]]; then
		echo -e $(eval_gettext "Missing toolchain directory \${SYSROOT}") >&2
		exit 1
	fi
	if [[ ! -d "${SYSROOT}/etc/portage" ]]; then # No cross-compilation
		unset SYSROOT
	fi
	createMakeConf "${chost}"
	[[ -r /usr/share/portage/config/repos.conf ]] && \
		cp /usr/share/portage/config/repos.conf "${PORTAGE_CONFIGROOT}"/etc/portage/repos.conf/gentoo.conf
	export EMERGE_LOG_DIR="${PORTAGE_CONFIGROOT}"/var/log/portage
	mkdir -p "${EMERGE_LOG_DIR}" || exit 1
	export ROOT="${project_dir}"/distroot
	mkdir -p "${ROOT}" || exit 1
	cat >"${project_dir}"/_env <<-EOF
		export ROOT="${ROOT}"
		export PORTAGE_CONFIGROOT="${PORTAGE_CONFIGROOT}"
		export EMERGE_LOG_DIR="${EMERGE_LOG_DIR}"
	EOF
	if [[ ! -z "${SYSROOT}" ]]; then
		echo "export SYSROOT=\"${SYSROOT}\"" >>"${project_dir}"/_env
	fi

	# Patch
	if [[ -r "${profile_dir}"/MisybaG.patch ]]; then
		pushd "${project_dir}" >/dev/null
		patch -p1 <"${profile_dir}"/MisybaG.patch >/dev/null || exit 1
		if [[ -r _custom/new.sh ]]; then
			chmod +x _custom/new.sh
			_custom/new.sh || exit 1
			rm _custom/new.sh
		fi
		popd >/dev/null
	fi

	# Terminated
	echo -e $(eval_gettext "Project created on directory:")
	echo "${project_dir}"
	echo -e $(eval_gettext "You should now mount your distant root to:")
	echo "${project_dir}"/distroot
}

############
# Install system.
sysInstall() {
	[[ -r _env ]] || exit 1
	source _env
	emerge -1 sys-apps/misybag-baselayout || exit 1
	local chost=$(emerge --info | grep '^CHOST\s*=' | sed 's/CHOST\s*=\s*"\?\([^"]*\)"\?/\1/')
	mkdir -p "${ROOT}/usr/lib/gcc/${chost}" || exit 1
	cp -dR "${SYSROOT}/usr/lib/gcc/${chost}"/* "${ROOT}/usr/lib/gcc/${chost}" || exit 1
	emerge --noreplace -1 @system || exit 1
	if [[ -r _config/id_rsa.pub ]]; then
		mkdir -p "${ROOT}"/root/.ssh || exit 1
		cat _config/id_rsa.pub >>"${ROOT}"/root/.ssh/authorized_keys || exit 1
		chmod 700 "${ROOT}"/root/.ssh
		chmod 600 "${ROOT}"/root/.ssh/authorized_keys
	fi
	_custom/sys_install.sh
	update
}

############
# Update target using defined configuration.
update() {
	[[ -r _env ]] || exit 1
	source _env
	cp -dR --preserve=mode -- _layout/* "${ROOT}"
	emerge --update --newuse --deep @world
	_custom/update.sh
}

############
# Script begining

# No parameter given
if [[ -z ${1} ]]; then
	help ${0}
	exit 1
fi

# Extract and execute action
action=${1}
shift
case ${action} in
	new)
		new "${@}"
	;;
	sys-install)
		sysInstall "${@}"
	;;
	update)
		update "${@}"
	;;
	*)
		echo -e $(eval_gettext "Unknown action \${action}.") >&2
		echo
		help ${0}
		exit 1
	;;
esac
