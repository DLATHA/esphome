#!/bin/bash

set -e

if [ ! -z "$TRAVIS_BUILD_DIR" ]; then
	export GITHUB_WORKSPACE="$TRAVIS_BUILD_DIR"
	export GITHUB_REPOSITORY="$TRAVIS_REPO_SLUG"
elif [ -z "$GITHUB_WORKSPACE" ]; then
	export GITHUB_WORKSPACE="$PWD"
	export GITHUB_REPOSITORY="esphome/async-mqtt-client"
fi

CHUNK_INDEX=$1
CHUNKS_CNT=$2
BUILD_PIO=0
if [ "$#" -lt 2 ] || [ "$CHUNKS_CNT" -le 0 ]; then
	CHUNK_INDEX=0
	CHUNKS_CNT=1
elif [ "$CHUNK_INDEX" -gt "$CHUNKS_CNT" ]; then
	CHUNK_INDEX=$CHUNKS_CNT
elif [ "$CHUNK_INDEX" -eq "$CHUNKS_CNT" ]; then
	BUILD_PIO=1
fi

if [ "$BUILD_PIO" -eq 0 ]; then
	# ArduinoIDE Test
	source ./.github/scripts/install-arduino-ide.sh
	source ./.github/scripts/install-arduino-core-esp8266.sh

	echo "Installing async-mqtt-client ..."
	cp -rf "$GITHUB_WORKSPACE" "$ARDUINO_USR_PATH/libraries/async-mqtt-client"

	FQBN="esp8266com:esp8266:generic:eesz=4M1M,ip=lm2f"
	build_sketches "$FQBN" "$GITHUB_WORKSPACE/examples"
	if [ ! "$OS_IS_WINDOWS" == "1" ]; then
		echo "Installing Arduino WiFi ..."
		git clone https://github.com/arduino-libraries/WiFi "$ARDUINO_USR_PATH/libraries/WiFi" > /dev/null 2>&1
		echo "Installing ESPAsyncTCP ..."
		git clone https://github.com/homeassistant/ESPAsyncTCP "$ARDUINO_USR_PATH/libraries/ESPAsyncTCP" > /dev/null 2>&1

		build_sketches "$FQBN" "$ARDUINO_USR_PATH/libraries/async-mqtt-client/examples"
	fi
else
	# PlatformIO Test
	source ./.github/scripts/install-platformio.sh
	echo "Installing Arduino WiFi"
	python -m platform lib -g install arduino-libraries/WiFi > /dev/null 2>&1
	git clone https://github.com/arduino-libraries/WiFi "$HOME/WiFi" > /dev/null 2>&1

	echo "Installing ESPAsyncTCP ..."
	python -m platformio lib --storage-dir "$GITHUB_WORKSPACE" install

	BOARD="esp12e"
	build_pio_sketches "$BOARD" "$GITHUB_WORKSPACE/examples"

	if [[ "$OSTYPE" != "cygwin" ]] && [[ "$OSTYPE" != "msys" ]] && [[ "$OSTYPE" != "win32" ]]; then
		echo "Installing Arduino WiFi"
		python -m platform lib -g install arduino-libraries/WiFi > /dev/null 2>&1
		git clone https://github.com/arduino-libraries/WiFi "$HOME/WiFi" > /dev/null 2>&1
		echo "Installing ESPAsyncTCP ..."
		python -m platformio lib -g install https://github.com/esphome/ESPAsyncTCP.git > /dev/null 2>&1
		git clone https://github.com/esphome/ESPAsyncTCP "$HOME/ESPAsyncTCP" > /dev/null 2>&1

		build_pio_sketches "$BOARD" "$HOME/async-mqtt-client/examples"
	fi
fi
