#!/bin/bash
set -e
# API URL
api_url="https://meta.fabricmc.net/v2/versions/"

# Example server's jar file name:
# fabric-server-mc.1.19.3-loader.0.14.14-launcher.0.11.1.jar

function check_version_valid {
  if [[ $(curl -s "$(echo $api_url)/loader/$(echo $version)") == "[]" ]]; then
    >&2 echo "Error: Invalid version selected: $version"
    exit 2
  else
    # Check if selected build exists
    if [ ! -z "$build" ]; then
      if [[ $(curl -s "$(echo $api_url)/loader/$(echo $version)/$(echo $build)") == "\"no loader version found for $(echo $version)\"" ]]; then
        >&2 echo "Error: Invalid build selected: $build"
        exit 2
      fi
    fi
  fi
}

function download_server {
  # Download the server
  echo "Downloading Fabric server..."
  echo "  - Version $version"
  echo "  - Build $download_build"
  echo "  - Installer $latest_installer"
  curl "$(echo $api_url)/loader/$(echo $version)/$(echo $download_build)/$(echo $latest_installer)/server/jar" -o "./fabric-server-mc.$(echo $version)-loader.$(echo $download_build)-launcher.$(echo $latest_installer).jar"
  echo "Download complete."
}

function check_updates {
  if [[ $server_file == false ]]; then
    download_build=$latest_build
    update_version=true
    update_build=true
  else
    echo Checking for updates...
  fi

  # Check if $build is empty
  if [[ -z $build ]]; then
    # Check if the current version is the same as the one selected
    if [[ $current_version == $version ]]; then
      # Check if the current build is the same as the one selected
      if [[ $current_build == $latest_build ]]; then
        echo "Server is up to date."
      else
        echo "Server is not up to date."
        download_build=$latest_build
        update_build=true
      fi
    else
      # Check if $server_file is false
      ask_version_differs
      echo "Server is not up to date."
      download_build=$latest_build
      update_version=true
    fi
  else
    # Check if the current version is the same as the one selected
    if [[ $current_version == $version ]]; then
      # Check if the current build is the same as the one selected
      if [[ $current_build == $build ]]; then
        echo "Server is up to date."
      else
        echo "Server is not up to date."
        download_build=$build
        update_build=true
      fi
    else
      # Check if $server_file is false
      ask_version_differs
      echo "Server is not up to date."
      download_build=$build
      update_version=true
    fi
  fi
}

# Get the latest build number and installer version
function get_latest_build {
    # Get the latest build number
    latest_build=$(curl -s "$(echo $api_url)/loader/$version" | jq -r '.[0].loader.version')
    latest_installer=$(curl -s "$(echo $api_url)/installer/" | jq -r '.[0].version')
}

# Check if the server is up to date and update if it isn't
function check_and_update {
  if ! [[ $server_file == false ]]; then
    echo Checking for updates...
  fi

  # Get the latest build number
  get_latest_build

  # Check if the current version is up to date
  check_updates

  # Check if $build_update is true or $version_update is true
  if [[ $update_build == true ]] || [[ $update_version == true ]]; then
    if [[ $server_file != false ]]; then
      old_server_file=$server_file
      server_file="fabric-server-mc.$version-loader.$download_build-launcher.$latest_installer.jar"
      download_server
      # Delete the old server file
      delete_old_server
    else
      server_file="fabric-server-mc.$version-loader.$download_build-launcher.$latest_installer.jar"
      download_server
    fi
  fi
  echo
  echo
}
