#!/bin/sh

# PLEASE NOTE: Exit codes used here are to ensure the container only ever restarts if there is a runtime error,
#              and does not end up in a restart loop due to a setup issue

ERROR_DESCRIPTION_PERMISSIONS_GENERIC="If this folder has been bind mounted, please ensure the container's UID has read and write access."


echo "[Setup]   Checking if we're running as root..."
CONTAINER_UID=$(id -u)

if [ "$CONTAINER_UID" = "0" ]; then
    echo "Do not run this container as a root user. Please either set a user ID in the compose file, or provide --user when starting the container."
    exit 0
else
    echo "Container running as UID $CONTAINER_UID"
fi


echo "[Setup]   Downloading CreativerseServer using SteamCMD..."

#if steamcmd +force_install_dir $CREATIVERSE_DIR_DATA +login anonymous +app_update 1098260 +quit; then
if steamcmd +login anonymous +app_update 1098260 +quit; then
    echo "CreativerseServer updated successfully"
else
    echo "Failed to run SteamCMD"
    exit 0
fi


echo "[Setup]   Testing backup/save/template folder permissions..."

if touch $CREATIVERSE_DIR_BACKUPS/permissions_test_file && rm $CREATIVERSE_DIR_BACKUPS/permissions_test_file; then
    echo "Backup folder permissions OK"
else
    echo "Failed to write to backup folder. $ERROR_DESCRIPTION_PERMISSIONS_GENERIC"
    exit 0
fi

if touch $CREATIVERSE_DIR_WORLDS/permissions_test_file && rm $CREATIVERSE_DIR_WORLDS/permissions_test_file; then
    echo "World folder permissions OK"
else
    echo "Failed to write to world folder. $ERROR_DESCRIPTION_PERMISSIONS_GENERIC"
    exit 0
fi

if mkdir --verbose --parents $CREATIVERSE_DIR_TEMPLATES/dltemplates $CREATIVERSE_DIR_TEMPLATES/templates; then
    echo "Template folder permissions OK, created dltemplates and templates folders."
else
    echo "Failed to write to template folder. $ERROR_DESCRIPTION_PERMISSIONS_GENERIC"
    exit 0
fi


echo "[Setup]   Creating server.json config..."

if mkdir --verbose --parents "$CREATIVERSE_DIR_CONFIGURATION"; then
   echo "Config folder ready"
else
   echo "Failed to create the config folder. $ERROR_DESCRIPTION_PERMISSIONS_GENERIC"
   exit 0
fi

# Pass arguments to jq, and have it output them as a JSON structure
CREATIVERSE_SERVER_CONFIG=$(jq --null-input \
                               --arg TemplateOverridePath $CREATIVERSE_DIR_TEMPLATES \
                               --arg WorldOverridePath $CREATIVERSE_DIR_WORLDS \
                               --arg WorldBackupOverridePath $CREATIVERSE_DIR_BACKUPS \
                               --argjson AlwaysFullyVerifyTemplateFile $CREATIVERSE_SERVER_ALWAYSFULLYVERIFYTEMPLATEFILE \
                               --argjson MaxMigrationDownloadThreads $CREATIVERSE_SERVER_MAXMIGRATIONDOWNLOADTHREADS \
                               '$ARGS.named')

if echo $CREATIVERSE_SERVER_CONFIG > "$CREATIVERSE_DIR_CONFIGURATION/server.json"; then
    echo "Saved server.json"
    echo $CREATIVERSE_SERVER_CONFIG
else
    echo "Failed to write server.json to the config folder. $ERROR_DESCRIPTION_PERMISSIONS_GENERIC"
    exit 0
fi


echo "[Setup]   Configuring backup preferences..."

# Open original persistence file from data folder, save it to the config folder
if jq ".Backups[].MaxToKeep=$CREATIVERSE_WORLD_BACKUPS_TO_KEEP" "$CREATIVERSE_DIR_DATA/persistence.json" | sponge "$CREATIVERSE_DIR_CONFIGURATION/persistence.json" && \
   jq ".Backups.Interval.IntervalMinutes=$CREATIVERSE_WORLD_BACKUPS_MINIMUM_INTERVAL_MINS" "$CREATIVERSE_DIR_CONFIGURATION/persistence.json" | sponge "$CREATIVERSE_DIR_CONFIGURATION/persistence.json"; then
    echo "Backups successfully set to retain $CREATIVERSE_WORLD_BACKUPS_TO_KEEP copies, minimum every $CREATIVERSE_WORLD_BACKUPS_MINIMUM_INTERVAL_MINS minutes"
else
    echo "Failed to configure preferences for backups"
    exit 0
fi


echo "[Setup]   Linking Creativerse Steam Client library..."

CREATIVERSE_STEAM_LIB_PATH_x86_64=/root/.steam/sdk64/steamclient.so
if [ ! -L "$CREATIVERSE_STEAM_LIB_PATH_x86_64" ]; then
    if ln -s "$CREATIVERSE_DIR_DATA/linux64/steamclient.so" "$CREATIVERSE_STEAM_LIB_PATH_x86_64"; then
        echo "Steam Client library link successfully created"
    else
        echo "Failed to setup Steam Client library link in the Configuration folder"
        exit 0
    fi
else
    echo "(i)     Link already exists"
fi


echo "[Setup]   Identifying world file..."

if [ "$CREATIVERSE_WORLD_KEY" = "AUTO" ]; then
    # List folders (worlds) in order of last modified, take first result
    LATEST_WORLD_KEY=$(cd $CREATIVERSE_DIR_WORLDS && ls -td -- */ | head -n 1)

    if [ -n "$LATEST_WORLD_KEY" ]; then
        CREATIVERSE_WORLD_KEY=$LATEST_WORLD_KEY
        echo "Auto-selected world key '$CREATIVERSE_WORLD_KEY'. To override this, please specify the correct key in the CREATIVERSE_WORLD_KEY environment variable"
    else
        echo "No world was found for auto-selection. Please ensure you have pasted your world data folder into the correct location."
        exit 0
    fi
fi
# TODO: check to see if a manually provided world key exists


echo "[Setup]   Checking world file..."

WORLD_FILE_JSON_PATH=$CREATIVERSE_DIR_WORLDS/$CREATIVERSE_WORLD_KEY/config_world.json
WORLD_FILE_JSON_VALUE_PRIVATESERVER_BOOL=$(jq .PrivateServer $WORLD_FILE_JSON_PATH)
WORLD_FILE_JSON_VALUE_TEMPLATEKEY_STR=$(jq .TemplateKey $WORLD_FILE_JSON_PATH)
WORLD_FILE_JSON_VALUE_GAMEPORT_INT=$(jq .GamePort $WORLD_FILE_JSON_PATH)

if [ -e "$WORLD_FILE_JSON_PATH" ]; then
    echo "World config file exists"
else
    echo "Cannot read the world's config file. Please ensure you have pasted your world data folder into the correct location."
    exit 0
fi

if [ $WORLD_FILE_JSON_VALUE_GAMEPORT_INT -ne 26900 ]; then
    echo "!!        WARNING: Your world is using a different gameport than expected"
fi

if [ $WORLD_FILE_JSON_VALUE_PRIVATESERVER_BOOL = "false" ]; then
    echo "!!        WARNING: Your world config is not set to private server. Unwanted players may be able to discover your server publicly and connect at will."
fi

# I don't think we need to download templates, this is handled by the server
#if ls -l | grep WORLD_FILE_JSON_VALUE_TEMPLATEKEY_STR; then
#    echo "          Template OK"
#else
#    echo "(i)       World template not found, downloading from mod.io..."
#fi


echo "[Setup]   Launching server..."

cd "$CREATIVERSE_DIR_DATA"
./CreativerseServer -worldId=$CREATIVERSE_WORLD_KEY -forceIp=0.0.0.0
