#!/usr/bin/env bash

set -euf -o pipefail

# Usage within current repo:
# - `cd sfdx-cli`
# - `../scripts/generate-sfdx-cli-pkgbuild.sh`
# - `git diff sfdx-cli`
# - If there are changes, copy PKGBUILD and .SRCINFO to AUR repo, commit and push

OUTPUT_DIR=${1:-`pwd`}

# Get and parse the manifest file from Salesforce
manifest_content=$(curl -s https://developer.salesforce.com/media/salesforce-cli/manifest.json)
sfdx_original_version=$(echo "$manifest_content" | jq '.version')
# PKGBUILD pkgver does not accept dash, so we convert that to underscore
sfdx_version=${sfdx_original_version//-/_}
sfdx_download_x86_64_url=$(echo "$manifest_content" | jq '.archives."linux-x64".url')
sfdx_download_x86_64_sha256=$(echo "$manifest_content" | jq '.archives."linux-x64".sha256')

# Generate PKGBUILD based on template
cat << EOF > "${OUTPUT_DIR}/PKGBUILD"
# Maintainer: Dang Mai <contact at dangmai dot net>

pkgname=sfdx-cli
pkgver=${sfdx_version}
pkgrel=1
_dirname="\${pkgname}-v\${pkgver}"
pkgdesc="a tool for creating and managing Salesforce DX projects from the command line"
arch=('x86_64')
url="https://developer.salesforce.com/tools/sfdxcli"
license=('unknown')
optdepends=('gnome-keyring: saving default credentials')
provides=('sfdx-cli')
options=(!strip)
conflicts=()
source_x86_64=(${sfdx_download_x86_64_url})

package() {
    _arch="x64"
    cd "\${srcdir}"

    install -dm 755 "\${pkgdir}"/opt
    install -dm 755 "\${pkgdir}"/usr/bin
    sfdx_dir="sfdx-cli-v${sfdx_original_version}-linux-\${_arch}"
    cp -a "\${sfdx_dir}" "\${pkgdir}"/opt/sfdx-cli
    ln -s /opt/sfdx-cli/bin/sfdx "\${pkgdir}"/usr/bin/sfdx
}
sha256sums_x86_64=(${sfdx_download_x86_64_sha256})
EOF
pushd "${OUTPUT_DIR}" > /dev/null
makepkg --printsrcinfo > .SRCINFO
popd > /dev/null

grep "pkgver" .SRCINFO | cut -f2 -d '=' | xargs