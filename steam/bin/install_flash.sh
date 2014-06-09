#!/bin/sh

STEAM_DIR=/storage/.xbmc/addons/multimedia.steam

# Download and install flash player (I think Steam can only use the 32bit flash anyway)
if [ ! -f $STEAM_DIR/.local/share/Steam/ubuntu12_32/plugins/libflashplayer.so ]; then 
  FLASH_URL_i386="http://fpdownload.adobe.com/get/flashplayer/current/install_flash_player_11_linux.i386.tar.gz"
  PLUGIN_DIR="$STEAM_DIR/.local/share/Steam/ubuntu12_32/plugins"
  FLASH_FILE="/tmp/flash.tar.gz"
  
  mkdir -p $PLUGIN_DIR

  ARCH=`uname -m`
  if [ "$ARCH" = "x86_64" ]; then
    FLASH_URL="$FLASH_URL_i386"
  else
    FLASH_URL="$FLASH_URL_i386"
  fi
 
  wget -O "$FLASH_FILE" "$FLASH_URL"
  tar xf "$FLASH_FILE" -C "$PLUGIN_DIR" libflashplayer.so
  chmod +x "$PLUGIN_DIR/libflashplayer.so"
fi
