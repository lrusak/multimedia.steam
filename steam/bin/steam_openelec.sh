#!/bin/sh

################################################################################
#      This file is part of OpenELEC - http://www.openelec.tv
#      Copyright (C) 2009-2012 Stephan Raue (stephan@openelec.tv) & ultraman
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

. /etc/profile

unset RESET_STEAM
unset STEAM_DEBUG
unset DEBUGGER

# Get argvs
for arg in "$@"; do
  case $arg in
    windowed)
      LAUNCH_OPTIONS="-windowed"
      ;;
    bigpicture)
      LAUNCH_OPTIONS="-windowed -bigpicture"
      ;;
    steamos)
      LAUNCH_OPTIONS="-windowed -bigpicture -steamos"
      ;;
    reset)
      RESET_STEAM=1
      ;;
    debug)
      #export DEBUGGER=gdb
      set -x
      ;;
  esac
done

# Setup variables
XBMC_STOP="true"
ADDON_DIR="/storage/.xbmc/addons/multimedia.steam"
ADDON_DATA_DIR="/storage/.xbmc/userdata/addon_data/multimedia.steam"
PLATFORM="ubuntu12_32"
STEAMBOOTSTRAPFILE="$ADDON_DIR/usr/lib/steam/bootstraplinux_$PLATFORM.tar.xz"
STEAMROOT="$ADDON_DIR/.local/share/Steam"
STEAMCONFIG="$ADDON_DIR/.steam"
STEAMDATALINK="$STEAMCONFIG/steam"
STEAMBIN32LINK="$STEAMCONFIG/bin32"
STEAMBIN64LINK="$STEAMCONFIG/bin64"
STEAMSDK32LINK="$STEAMCONFIG/sdk32" # 32-bit steam api library
STEAMSDK64LINK="$STEAMCONFIG/sdk64" # 64-bit steam api library
STEAMROOTLINK="$STEAMCONFIG/root" # points at the Steam install path for the currently running Steam
STEAMSTARTING="$STEAMCONFIG/starting"
STEAM_RUNTIME="$STEAMROOT/$PLATFORM/steam-runtime"
RUNTIME_URL="http://media.steampowered.com/client/runtime/steam-runtime-release_2014-02-05.tar.xz" # this may be needed if steam fails to launch first time
ARCHIVE_EXT=tar.xz
PIDFILE="$STEAMCONFIG/steam.pid" # pid of running steam for this user
MAGIC_RESTART_EXITCODE=42
SEGV_EXITCODE=139

# See if this is the initial launch of Steam
if [ ! -f "$PIDFILE" ] || kill -0 $(cat "$PIDFILE") 2>/dev/null; then
  INITIAL_LAUNCH=true
fi

if [ ! -d "$STEAMROOT" ]; then
  mkdir -p "$STEAMROOT"
fi

if [ ! -d "$STEAMCONFIG" ]; then
  mkdir -p "$STEAMCONFIG"
fi

# Setup links and directories
if [ "$STEAMROOT" != "$(readlink $STEAMROOTLINK)" -a "$STEAMROOT" != "$(readlink $STEAMDATALINK)" ]; then
  rm -f "$STEAMBIN32LINK" && ln -s "$STEAMROOT/$PLATFORM32" "$STEAMBIN32LINK"
  rm -f "$STEAMBIN64LINK" && ln -s "$STEAMROOT/$PLATFORM64" "$STEAMBIN64LINK"
  rm -f "$STEAMSDK32LINK" && ln -s "$STEAMROOT/linux32" "$STEAMSDK32LINK"
  rm -f "$STEAMSDK64LINK" && ln -s "$STEAMROOT/linux64" "$STEAMSDK64LINK"
  rm -f "$STEAMROOTLINK" && ln -s "$STEAMROOT" "$STEAMROOTLINK"
  if [ ! -d "$STEAMDATALINK" ]; then
    rm -f "$STEAMDATALINK" && ln -s "$STEAMROOT" "$STEAMDATALINK"
  fi
fi

# Setup addon_data folder with screenshot and backups
if [ ! -d "$ADDON_DATA_DIR" ]; then
  mkdir -p "$ADDON_DATA_DIR/Screenshots"
fi

# Link backups folder to steam backup folder.
ln -s "$ADDON_DIR/.local/share/Steam/Backups" "$ADDON_DATA_DIR/Backups"

if [ ! -f "$HOME_DIR/settings.xml" ]; then
  cp "$ADDON_DIR/resources/settings.xml" "$HOME_DIR/"
fi

# Check settings
# Window Manager
if [ ! -z "`cat $ADDON_DATA_DIR/settings.xml | grep windowmanager_stop | grep true`" ]; then
  WINDOWMANAGER_STOP="true"
fi
# eventlircd
if [ ! -z "`cat $ADDON_DATA_DIR/settings.xml | grep eventlircd_stop | grep true`" ]; then
  EVENTLIRCD_STOP="true"
fi

# asound.conf needs a dmix option to use bigpicture mode
export SDL_AUDIODRIVER="alsa"

# Export language locale (not sure if this is needed)
export LANG="en_US.UTF-8"
export LC_CTYPE="en_US.UTF-8"
export LC_MESSAGES="en_US.UTF-8"
export LC_COLLATE="en_US.UTF-8"
export LC_ALL="en_US.UTF-8"

# Export new home path because steam needs to install there
export HOME="$ADDON_DIR"

# Test this out (only for nvidia!)
if [ -f /proc/driver/nvidia/version ]; then
  export __GL_THREADED_OPTIMIZATIONS=1
fi

# disable SDL1.2 DGA mouse because we can't easily support it in the overlay
export SDL_VIDEO_X11_DGAMOUSE=0 

# This allows steam to be closed with the "x" instead of just minimizing it
export STEAM_FRAME_FORCE_CLOSE=1

# Keep the original paths
export SYSTEM_PATH="$PATH"
export SYSTEM_LD_LIBRARY_PATH="$LD_LIBRARY_PATH"

# Export special variales
export PANGO_RC_FILE="$ADDON_DIR/etc/pango/pangorc"
export DBUS_SESSION_BUS_ADDRESS="unix:path=/var/run/dbus/system_bus_socket"

install_bootstrap() {
	cp "$STEAMBOOTSTRAPFILE" "$STEAMROOT/bootstrap.tar.xz"
	cd "$STEAMROOT"
	if ! tar xJf "$STEAMBOOTSTRAPFILE" ; then
		echo $"Failed to extract $STEAMBOOTSTRAPFILE, aborting installation."
		exit 1
	fi
}

extract_archive()
{
		echo "$1"
		tar -xf "$2" -C "$3"
		return $?
}

has_runtime_archive()
{
	# Make sure we have files to unpack
	for file in "$STEAM_RUNTIME.$ARCHIVE_EXT".part*; do
		if [ ! -f "$file" ]; then
			return 1
		fi
	done

	if [ ! -f "$STEAM_RUNTIME.checksum" ]; then
		return 1
	fi

	return 0
}

unpack_runtime()
{
	if ! has_runtime_archive; then
		if [ -d "$STEAM_RUNTIME" ]; then
			# The runtime is unpacked, let's use it!
			return 0
		fi
		return 1
	fi

	# Make sure we haven't already unpacked them
	if [ -f "$STEAM_RUNTIME/checksum" ]; then
		return 0
	fi

	# Unpack the runtime
	EXTRACT_TMP="$STEAM_RUNTIME.tmp"
	rm -rf "$EXTRACT_TMP"
	mkdir "$EXTRACT_TMP"
	cat "$STEAM_RUNTIME.$ARCHIVE_EXT".part* >"$STEAM_RUNTIME.$ARCHIVE_EXT"
	EXISTING_CHECKSUM="$(cd "$(dirname "$STEAM_RUNTIME")"; md5sum "$(basename "$STEAM_RUNTIME.$ARCHIVE_EXT")")"
	EXPECTED_CHECKSUM="$(cat "$STEAM_RUNTIME.checksum")"
	if [ "$EXISTING_CHECKSUM" != "$EXPECTED_CHECKSUM" ]; then
		echo $"Runtime checksum: $EXISTING_CHECKSUM, expected $EXPECTED_CHECKSUM" >&2
		return 2
	fi
	if ! extract_archive $"Unpacking Steam Runtime" "$STEAM_RUNTIME.$ARCHIVE_EXT" "$EXTRACT_TMP"; then
		return 3
	fi

	# Move it into place!
	if [ -d "$STEAM_RUNTIME" ]; then
		rm -rf "$STEAM_RUNTIME.old"
		if ! mv "$STEAM_RUNTIME" "$STEAM_RUNTIME.old"; then
			return 4
		fi
	fi
	if ! mv "$EXTRACT_TMP"/* "$EXTRACT_TMP"/..; then
		return 5
	fi
	rm -rf "$EXTRACT_TMP"
	if ! cp "$STEAM_RUNTIME.checksum" "$STEAM_RUNTIME/checksum"; then
		return 6
	fi
	return 0
}

reset_steam() {
	if [ ! -z "$INITIAL_LAUNCH" ]; then
		exit 1
	fi

	if [ ! -f "$STEAMBOOTSTRAPFILE" ]; then
		exit 2
	fi

	STEAM_SAVE="$STEAMROOT/.save"

	# Don't let the user interrupt us, or they may corrupt the install
	trap ignore_signal INT

	# Back up games and critical files
	mkdir -p "$STEAM_SAVE"
	for i in bootstrap.tar.xz ssfn* SteamApps userdata; do
		if [ -e "$i" ]; then
			mv -f "$i" "$STEAM_SAVE/"
		fi
	done
	for i in "$STEAMCONFIG/registry.vdf"; do
		mv -f "$i" "$i.bak"
	done

	# Scary!
	rm -rf "$STEAMROOT/"*

	# Move things back into place
	mv -f "$STEAM_SAVE/"* "$STEAMROOT/"
	rmdir "$STEAM_SAVE"

	# Okay, at this point we can recover, so re-enable interrupts
	trap '' INT

	# Reinstall the bootstrap and we're done.
	install_bootstrap
}

start_steam() {
  # Unpack the runtime if necessary
  if unpack_runtime; then
    case $(uname -m) in
    *64)
      export PATH="$STEAM_RUNTIME/amd64/bin:$STEAM_RUNTIME/amd64/usr/bin:$PATH"
      ;;
    *)
      export PATH="$STEAM_RUNTIME/i386/bin:$STEAM_RUNTIME/i386/usr/bin:$PATH"
      ;;
    esac
    export LD_LIBRARY_PATH="$STEAM_RUNTIME/i386/lib/i386-linux-gnu:$STEAM_RUNTIME/i386/lib:$STEAM_RUNTIME/i386/usr/lib/i386-linux-gnu:$STEAM_RUNTIME/i386/usr/lib:$STEAM_RUNTIME/amd64/lib/x86_64-linux-gnu:$STEAM_RUNTIME/amd64/lib:$STEAM_RUNTIME/amd64/usr/lib/x86_64-linux-gnu:$STEAM_RUNTIME/amd64/usr/lib:$LD_LIBRARY_PATH"

  fi
    
  ulimit -n 2048 2>/dev/null
  
  # Touch steam startup file so we can detect bootstrap launch failure
  : >"$STEAMSTARTING"
  
  # Prepend steam specific lib path to LD_LIBRARY_PATH
  export LD_LIBRARY_PATH="$STEAMROOT/$PLATFORM:$LD_LIBRARY_PATH"
  
  # Stop windowmanager if asked to otherwise make sure it is started
  if [ "$WINDOWMANAGER_STOP" = "true" ]; then
    systemctl stop windowmanager
  else
    systemctl start windowmanager
  fi

  # Stop eventlircd if asked to
  if [ "$EVENTLIRCD_STOP" = "true" ]; then
    systemctl stop eventlircd
  fi

  # Stop xbmc
  if [ "$XBMC_STOP" = "true" ]; then
    killall -STOP xbmc.bin
  fi
  
  (
  # Check for DEBUGGER else just start steam
  if [ "$DEBUGGER" ]; then
    ARGSFILE=$(mktemp /var/tmp/steam.gdb.XXXXXX)
    gdb -x "$ARGSFILE" --args $ADDON_DIR/.local/share/Steam/ubuntu12_32/steam $LAUNCH_OPTIONS
  else
    exec $ADDON_DIR/.local/share/Steam/ubuntu12_32/steam $LAUNCH_OPTIONS
  fi
  )&
}

if [ ! -f "$STEAMROOT/$PLATFORM/steam" ]; then
	install_bootstrap
fi

# Start steam
if [ "$RESET_STEAM" ]; then
  reset_steam
else
  start_steam
fi

# Get PID of steam
STEAMPID=$!

# Wait for steam to close
wait "$STEAMPID"

# Get steam exit status
STATUS=$?

# Restore variables
export HOME="/storage"
export PATH="$SYSTEM_PATH"
export LD_LIBRARY_PATH="$SYSTEM_LD_LIBRARY_PATH"

# If steam requested to restart, then restart
if [ "$STATUS" -eq "$MAGIC_RESTART_EXITCODE" ] ; then
  exec "$0" "$@"
fi

# Restore file permissions
chmod 777 -R "$ADDON_DIR"

# Start windowmanager if asked to
if [ "$WINDOWMANAGER_STOP" = "true" ]; then
  systemctl start windowmanager
else
  systemctl stop windowmanager
fi

# Start eventlircd if asked to
if [ "$EVENTLIRCD_STOP" = "true" ]; then
  systemctl start eventlircd
fi

# Start XBMC
if [ "$XBMC_STOP" = "true" ]; then  
  killall -CONT xbmc.bin
fi
