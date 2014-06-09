#!/bin/sh

################################################################################
#      This file is part of OpenELEC - http://www.openelec.tv
#      Copyright (C) 2009-2012 Stephan Raue (stephan@openelec.tv)
#
#  This Program is free software; you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published by
#  the Free Software Foundation; either version 2, or (at your option)
#  any later version.
#
#  This Program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
#  GNU General Public License for more details.
#
#  You should have received a copy of the GNU General Public License
#  along with OpenELEC.tv; see the file COPYING.  If not, write to
#  the Free Software Foundation, 51 Franklin Street, Suite 500, Boston, MA 02110, USA.
#  http://www.gnu.org/copyleft/gpl.html
################################################################################

PKG_NAME="steam"
PKG_VERSION="05e3d6e"
PKG_REV="1"
PKG_ARCH="i386"
PKG_LICENSE="OSS"
PKG_SITE="http://store.steampowered.com/about/"
PKG_URL="http://storage.freestylephenoms.com/${PKG_NAME}-${PKG_VERSION}.tar.bz2"
PKG_DEPENDS=""
PKG_BUILD_DEPENDS=""
PKG_PRIORITY="optional"
PKG_SECTION="multimedia"
PKG_SHORTDESC=""
PKG_LONGDESC=""
PKG_IS_ADDON="yes"
PKG_ADDON_TYPE="xbmc.python.script"
PKG_AUTORECONF="no"

make_target() {
  : # nothing to do here
}

makeinstall_target() {
  : # nothing to do here
}

addon() {
  mkdir -p $ADDON_BUILD/$PKG_ADDON_ID/usr
    cp -r $BUILD/${PKG_NAME}-${PKG_VERSION}/usr/lib $ADDON_BUILD/$PKG_ADDON_ID/usr/

    cp -r $PKG_DIR/bin $ADDON_BUILD/$PKG_ADDON_ID/
    cp -r $PKG_DIR/etc $ADDON_BUILD/$PKG_ADDON_ID/
    cp -r $PKG_DIR/resources $ADDON_BUILD/$PKG_ADDON_ID/

  chmod -R 755 $ADDON_BUILD/$PKG_ADDON_ID
}
