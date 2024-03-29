#!/bin/bash
set -e
#############################################################################################################
#                                         MinecraftServerMANager                                            #
#                                              by jiriks74                                                  #
#                                  https://github.com/jiriks74/msman.sh                                     #
#  This script is under GPLv3, if you want to distribute changes you have to do so under the same license   #
#                            and acknowledge the original script and author.                                #
#############################################################################################################

CURRENT_SCRIPT_VERSION="v2.1.6"

# --------------------------------------------------
# You shouldn't need to change anything in this file
# Settings are located in 'msman.cfg'
# --------------------------------------------------
#
# The url of the script (used for updating)
REPO_OWNER="jiriks74"
REPO_NAME="msman.sh"

# Check for dependencies
function check_dependencies {
  # Check if curl is installed
  if ! command -v curl &> /dev/null
  then
      echo "Error: Curl is not installed"
      exit 1
  fi

  # Check if jq is installed
  if ! command -v jq &> /dev/null
  then
      echo "Error: jq is not installed"
      exit 1
  fi

  # Check if awk is installed
  if ! command -v awk &> /dev/null
  then
      echo "Error: awk is not installed"
      exit 1
  fi

  # Check if screen is installed
  if ! command -v screen &> /dev/null
  then
      echo "Error: screen is not installed"
      exit 1
  fi
  
  # Check if tar is installed
  if ! command -v tar &> /dev/null
  then
      echo "Error: tar is not installed"
      exit 1
  fi

  # Check if gzip is installed
  # TODO: Check if this is needed and/or works
  # if ! command -v gzip &> /dev/null
  # then
  #     echo "Error: gzip is not installed"
  #     exit 1
  # fi
}

# Ask if the user wants to continue anyway
# If the user doesn't answer in 15 seconds, the script will exit
function ask_continue {
  if [[ $java_version_override != true ]]; then
    answer=""
    echo "You have 15 seconds to respond before the script exits."
    read -t 15 -p "Do you want to continue anyway? [y/N]: " answer
    if [[ $answer != "y" ]] && [[ $answer != "Y" ]]; then
        echo "Exiting..."
        exit 1
    fi
  fi
}

# Set arguments for java
function set_java_args {
  # Check if $override_flags is not true
  if [[ $override_flags != true ]]; then
    if [[ "${mem%M}" -gt 12000 ]]; then
      G1NewSize=40
      G1MaxNewSize=50
      G1HeapRegionSize=16M
      G1Reserve=15
      InitiatingHeapOccupancy=20
    else
      G1NewSize=30
      G1MaxNewSize=40
      G1HeapRegionSize=8M
      G1Reserve=20
      InitiatingHeapOccupancy=15
    fi
    # Aikar's flags are used by default
    # See https://docs.papermc.io/paper/aikars-flags
    java_launchoptions="-Xms$mem -Xmx$mem -XX:+UseG1GC -XX:+ParallelRefProcEnabled -XX:MaxGCPauseMillis=200 -XX:+UnlockExperimentalVMOptions -XX:+DisableExplicitGC -XX:+AlwaysPreTouch -XX:G1NewSizePercent=$G1NewSize -XX:G1MaxNewSizePercent=$G1MaxNewSize -XX:G1HeapRegionSize=$G1HeapRegionSize -XX:G1ReservePercent=$G1Reserve -XX:G1HeapWastePercent=5 -XX:G1MixedGCCountTarget=4 -XX:InitiatingHeapOccupancyPercent=$InitiatingHeapOccupancy -XX:G1MixedGCLiveThresholdPercent=90 -XX:G1RSetUpdatingPauseTimePercent=5 -XX:SurvivorRatio=32 -XX:+PerfDisableSharedMem -XX:MaxTenuringThreshold=1 -Dusing.aikars.flags=https://mcflags.emc.gs -Daikars.new.flags=true"
  fi
}

# Ask if the new server version differs from the old one
function ask_version_differs {
  echo
  echo
  echo "The current server version differs from the one you selected."
  echo "The server version is $current_version and the selected version is $version."
  echo "Do you want to update the server version?"
  echo "This can cause many issues if you don't know what you are doing."
  echo
  echo "I am not responsible for any data loss caused by updating the server version."
  echo
  echo "You have 15 seconds to respond, or the script will exit"
  read -t 15 -p "Do you want to update the server version? [y/N] " version_differs

  if [ "$version_differs" != "y" ] && [ "$version_differs" != "Y" ]; then
    echo "Server version not updated."
    echo "To start the server again with the current version, change the version in the config to $current_version."
    exit 4
  fi

  if [ "$version_differs" == "y" ] || [ "$version_differs" == "Y" ]; then
    read -t 15 -p "Are you sure you want to update the server version? [y/N] " version_differs
    if [ "$version_differs" != "y" ] && [ "$version_differs" != "Y" ]; then
      echo "Server version not updated."
      echo "To start the server again with the current version, change the version in the config to $current_version."
      exit 4
    fi
  fi
}

# Ask if the new server version differs from the old one
function ask_server_type_differs {
  echo
  echo
  echo "The current server type differs from the one you selected."
  echo "The server version is $existing_server_type and the selected type is $server_type."
  echo "Do you want to change the server type?"
  echo "This can cause many issues if you don't know what you are doing."
  echo
  echo "I am not responsible for any data loss caused by changing the server type."
  echo
  echo "You have 15 seconds to respond, or the script will exit"
  read -t 15 -p "Do you want to change the server type? [y/N] " type_differs

  if [ "$type_differs" != "y" ] && [ "$type_differs" != "Y" ]; then
    echo "Server type not changed."
    echo "To start the server again with the server type, change the server type in the config to $existing_server_type."
    exit 4
  fi

  if [ "$type_differs" == "y" ] || [ "$type_differs" == "Y" ]; then
    read -t 15 -p "Are you sure you want to change the server type? [y/N] " type_differs
    if [ "$type_differs" != "y" ] && [ "$type_differs" != "Y" ]; then
      echo "Server type not changed."
      echo "To start the server again with the server type, change the server type in the config to $existing_server_type."
      exit 4
    fi
  fi
}

# Ask if the new server version differs from the old one
function ask_server_differs {
  echo
  echo
  echo "The current server type differs from the one you selected."
  echo "The current server type is $current_server_type and the selected version is $server_type."
  echo "Do you want to change server types?"
  echo "This can cause many issues if you don't know what you are doing."
  echo
  echo "I am not responsible for any data loss caused by changing server types."
  echo
  echo "You have 15 seconds to respond, or the script will exit"
  read -t 15 -p "Do you want to change the server version type? [y/N] " version_differs

  if [ "$version_differs" != "y" ] && [ "$version_differs" != "Y" ]; then
    echo "Server version not updated."
    echo "To start the server again with the current version, change the version in the config to $current_version."
    exit 4
  fi

  if [ "$version_differs" == "y" ] || [ "$version_differs" == "Y" ]; then
    read -t 15 -p "Are you sure you want to update the server version? [y/N] " version_differs
    if [ "$version_differs" != "y" ] && [ "$version_differs" != "Y" ]; then
      echo "Server version not updated."
      echo "To start the server again with the current version, change the version in the config to $current_version."
      exit 4
    fi
  fi
}

# Accept EULA
function accept_eula {
  if test "$(cat eula.txt 2>/dev/null)" != "eula=true"; then
    first_run=true
    echo "'eula.txt' does not exist or EULA is not accepted"
    echo "You have to accept the Minecraft EULA to run the server"
    echo "By entering 'y' you are indicating your agreement to Minecraft's EULA (https://aka.ms/MinecraftEULA)."
    echo "You have 15 seconds to respond, or the script will exit"
    read -t 15 -p "Do you agree to the Minecraft EULA? [y/N] " eula_agreed

    if [ "$eula_agreed" == "y" ] || [ "$eula_agreed" == "Y" ]; then
      if [ ! -f eula.txt ]; then
        echo "eula=true" > eula.txt
      else
        rm eula.txt
        echo "eula=true" > eula.txt
      fi
      echo
      echo
      echo "EULA accepted"
      echo
      echo
    else
      echo
      echo
      echo "You did not agree to the Minecraft EULA"
      echo "Exiting..."
      exit 1
    fi
  fi
}

# Launch the server
function launch_server {
  echo "Starting the server..."
  echo
  echo
  java $java_launchoptions -jar $server_file $mc_launchoptions
}

# Helper scripts update
function helper_scripts_update {
  # Download matching version of helper scripts
  echo "Updating helper scripts..."
  # Download the file into ms-man-helper.tar.gz
  if [[ $(curl -sLJ -w '%{http_code}\n' "https://github.com/$REPO_OWNER/$REPO_NAME/releases/download/$CURRENT_SCRIPT_VERSION/msman-helper.tar.gz" -o msman-helper.tar.gz) == 200 ]]; then
    # Extract the files from ms-man-helper.tar.gz
    tar -xzf msman-helper.tar.gz
    if [ -d .msman ]; then
      # Remove the old scripts
      echo "Removing old helper scripts..."
      rm -rf .msman
      echo "Removed old script"
    fi
    echo "Moving new helper scripts into place..."
    mv msman/.msman .msman
    echo "Removing temporary files..."
    rm msman-helper.tar.gz
    rm -rf msman
    echo "Helper scripts updated successfully."
    EXTRA_SCRIPTS_VERSION=$(echo $CURRENT_SCRIPT_VERSION)
    echo
    echo
  else
    echo "Failed to update helper scripts."
    rm -rf msman
    rm msman-helper.tar.gz
    exit 5
  fi
}

# Download the update for the script
function self_update {
  # Download the latest version of the script
  echo "Updating script..."
  # Download the file into msman_new.sh
  if [[ $(curl -sLJ -w '%{http_code}\n' "https://github.com/$REPO_OWNER/$REPO_NAME/releases/download/$LATEST_SCRIPT_VERSION/msman.sh" -o msman_new.sh) == 200 ]]; then
    # Make the file executable
    chmod +x msman_new.sh
    # Remove the old script
    if [[ -f msman.sh ]]; then
      echo "Removing old script..."
      rm msman.sh
      echo "Removed old script"
    fi
    echo "Moving new script into place..."
    # Rename the new script
    mv msman_new.sh msman.sh
    echo "Moved new script into place"
    echo "Script updated successfully."
    echo
  else
    echo "Failed to update script."
    rm msman_new.sh
    exit 5
  fi
}

# Check helper scripts update
function check_helper_scripts {
  if [[ -d .msman ]]; then
    source "./.msman/version.sh"
    if [[ $CURRENT_SCRIPT_VERSION != $EXTRA_SCRIPTS_VERSION ]]; then
      echo "Helper script verion mismatch!"
      echo "Main script version: $CURRENT_SCRIPT_VERSION"
      echo "Helper script version: $EXTRA_SCRIPTS_VERSION"
      echo
      echo "The script will now download the same version of the helper scripts as the main script."
      helper_scripts_update
    fi
  else
    echo "Helper scripts not found."
    echo "The script will now download the helper scripts."
    helper_scripts_update
  fi
}

# Get latest script version
function get_latest_script_release {
  response=$(curl -sL "https://api.github.com/repos/$REPO_OWNER/$REPO_NAME/releases/latest")

  if [[ $response =~ "API rate limit exceeded" ]]; then
    echo "API limit exceeded. Will not check for updates."
    LATEST_SCRIPT_VERSION=$CURRENT_SCRIPT_VERSION
  else
    # Extract the latest version from the response
    LATEST_SCRIPT_VERSION=$(echo $response | jq -r ".tag_name")
  fi
}

# Function to update the script
function check_self_update {
  # Get the latest version of the script
  get_latest_script_release

  # Compare the current version with the latest version
  if [[ "$CURRENT_SCRIPT_VERSION" != "$LATEST_SCRIPT_VERSION" ]]; then
    echo "An update is available!"
    echo "Current version: $CURRENT_SCRIPT_VERSION"
    echo "Latest version: $LATEST_SCRIPT_VERSION"
    echo
    echo "The script will continue without updating in 15 seconds."
    echo "If you decide to update it is your responsibility to check the release notes for any breaking changes."
    read -t 15 -p "Do you want to update and read the release notes? [y/N]"
    if [ "$REPLY" == "y" ] || [ "$REPLY" == "Y" ]; then
      # Extract the release notes from the response
      RELEASE_NOTES=$(echo "$response" | jq -r ".body")

      # Print the release notes
      echo "$RELEASE_NOTES" | less

      # Ask the user if they want to update
      echo
      echo "The script will continue without updating in 15 seconds."
      echo "If you decide to update it is your responsibility to check the release notes for any breaking changes."
      read -t 15 -p "Do you want to update? [y/N] " update
      if [ "$update" == "y" ] || [ "$update" == "Y" ]; then
        self_update
        CURRENT_SCRIPT_VERSION=$LATEST_SCRIPT_VERSION
        check_helper_scripts
        bash -c "$(pwd)/msman.sh"
      else
        echo "Skipping update."
        return
      fi
    fi
    echo
    echo
  fi
}

# Load config
function load_config {
  # Check if the config file exists
  if [ ! -f msman.cfg ]; then
    echo "Config file does not exist."
    echo "Downloading the default config file..."
    # Download the default config file for the current version
    if [[ $(curl -sLJ -w '%{http_code}\n' "https://github.com/$REPO_OWNER/$REPO_NAME/releases/download/$CURRENT_SCRIPT_VERSION/msman.cfg" -o msman.cfg) == 200 ]]; then
      echo
      read -p "Do you want to edit the config file? [y/N] " edit_config
      if [ "$edit_config" == "y" ] || [ "$edit_config" == "Y" ]; then
        if [ -z "$EDITOR" ]; then
          >&2 echo "EDITOR is not set."
          >&2 echo "Open 'msman.cfg' manually."
          echo "Exiting..."
          exit 1
        else
          # Check if $EDITOR is installed
          if ! command -v $EDITOR &> /dev/null; then
            >&2 echo "$EDITOR is not installed."
            >&2 echo "Open 'msman.cfg' manually."
            echo "Exiting..."
            exit 1
          fi
          echo "Opening the config file in $EDITOR..."
          $EDITOR msman.cfg
        fi
      fi
    else
      >&2 echo "Failed to download the default config file."
      >&2 echo "Go to the GitHub repository for more information:"
      >&2 echo "https://github.com/$REPO_OWNER/$REPO_NAME"
      rm msman.cfg
      echo "Exiting..."
      exit 1
    fi
  fi

  # Load config
  source msman.cfg
}

# Delete old server file with name $old_server_file
function delete_old_server {
  # Delete the old server file
  echo "Deleting old server file '$server_file...'"
  rm "$old_server_file"
  echo "Old server file deleted."
}

# Load the rest of the script
function load_script {
  # DONE: Check if the script files exist
  #   - Checked in check_helper_scripts
  source "./.msman/detect_server.sh"
  source "./.msman/java.sh"

  # Load the correct script
  if [[ $server_type == "paper" ]]; then
    source "./.msman/paper.sh"
  elif [[ $server_type == "fabric" ]]; then
    source "./.msman/fabric.sh"
  # elif [[ $server_type == "vanilla" ]]; then
  #   source "$cwd/msman/vanilla.sh"
  # elif [[ $server_type == "forge" ]]; then
  #   source "$cwd/msman/forge.sh"
  else
    >&2 echo "Unknown server type."
    echo "Exiting..."
    exit 1
  fi
}

# First run
first_run() {
  if [[ $first_run == true ]]; then
    answer=""
    echo "Since eula wasn't accepted, this is probably the first run of the server."
    echo "If you want to install plugins (or mods), answer 'n' and you can do so."
    echo "If you don't answer, the server will start in 15 seconds."
    read -t 15 -p "Do you want to start the server now? [Y/n] " answer
    if [ "$answer" == "n" ] || [ "$answer" == "N" ]; then
      echo "Exiting..."
      exit 0
    fi
  fi
}

# Main function
function main {
  # Check dependencies
  check_dependencies
  
  # Load config
  load_config

  if [[ $check_for_script_updates == true ]]; then
    # Check for script updates
    check_self_update
  else
    echo "Skipping script update check."
  fi

  # Check helper scripts version mismatch
  check_helper_scripts

  # Load the rest of the script
  # Get the current server file, version and build
  load_script

  # Gets the installed server info
  get_existing_server

  # Check if the server type differs from the one in the config
  if [[ $server_file != false ]]; then
    if [[ $existing_server_type != $server_type ]]; then
      ask_server_differs
    fi
  fi

  # Check if the version and build are valid
  check_version_valid

  # Check if the correct java version is installed
  setup_java

  # Check if the server is up to date and if not, update it
  check_and_update

  # Accept EULA
  accept_eula

  # Check if this is the first run
  first_run

  # Set the java arguments
  set_java_args
  # Launch the server
  launch_server
}

if [[ "$1" == "--edit-config" ]] || [[ "$1" == "-e" ]]; then
  if ! command -v $EDITOR &> /dev/null; then
    echo "EDITOR is not set."
    echo "Open 'msman.cfg' manually."
    exit 1
  else
    $EDITOR msman.cfg
    exit 0
  fi
elif [[ "$1" == "--help" ]] || [[ "$1" == "-h" ]]; then
  echo "Usage: ./msman.sh [OPTION]"
  echo "Starts the Minecraft server."
  echo 
  echo "Options:"
  echo "  -e, --edit-config   Edit the config file."
  echo "  -h, --help          Show this help message."
  echo
  echo "To change the settings of the script, edit the 'msman.cfg' file."
  echo "If the file does not exist, it will be downloaded automatically when the script is run and you will be asked if you want to edit it."
  echo
  echo "For more information, see:"
  echo "https://github.com/$REPO_OWNER/$REPO_NAME"
  exit 0
else
  # Run the main function
  main
fi
