# Creativerse Standalone Server
An unofficial dockerized server for Playful's Creativerse

## Get started
### Suggested requirements
- 300MB disk space (for the CreativerseServer data files downloaded from Steam during startup, these can be relocated by editing the compose file)
- 2-10GB additional disk space (for any World Templates downloaded during startup, or preloaded by you, these can be relocated by editing the compose file)
- 8GB RAM (as per the wiki)


### Importing save files
Existing save files (worlds) are required for the server to operate. On Windows, you can find these in the following folder:

```
%localappdata%\PlayfulCorp\CreativerseServer\worlddata\worlds\
```

Each folder is named according to its __World Key__.

If you choose to store more than one world on the server, you'll need to set the optional `WORLD_KEY` environment variable to the World Key for the save file you wish to load. Otherwise, only the most recently created world will be loaded.

Your world folder should be placed in the `worlds` folder.


### Importing world templates
World templates can be placed in the `templates/dltemplates` folder. You may need to create the `dltemplates` folder inside `templates` if it does not exist.

Each template is about 2 GB in size. They can be manually downloaded from [mod.io](https://mod.io/g/creativerse).

If no templates are found when the server is started, the correct one for your world will be automatically downloaded.


## Server operations
### Accessing the Web UI
The Web UI can be accessed on port 26902. Various parameters relating to the game world can be configured via this interface. It may be a good idea to __avoid forwarding this port__ if you plan to expose your server to the internet.


### Backups
Creativerse automatically creates backups of your world. These will be placed into the `backups` folder. To customise the creation interval and amount of backups retained, see the available Environment Variables.


## Configuration
### Ports
The following ports are used:

|Port|Proto|Description|
|---|---|---|
|26900|UDP|Game|
|26901|UDP|Query|
|26902|TCP|Web Server|


### Environment variables
|Name|Description|Default value|
|---|---|---|
|`CREATIVERSE_WORLD_KEY`|Manually specify a world key to load. AUTO is a special value that identifies the most recent modified world and passes the key to Creativerse|`AUTO`|
|`CREATIVERSE_WORLD_BACKUPS_TO_KEEP`|Amount of Custom, Hourly, Daily and Weekly backups to keep|2|
|`CREATIVERSE_WORLD_BACKUPS_MINIMUM_INTERVAL_MINS`|Custom backup interval (in minutes)|5|
|`CREATIVERSE_SERVER_ALWAYSFULLYVERIFYTEMPLATEFILE`|Choose whether templates are always verified. This does not affect templates being downloaded automatically if they don't exist|false|


### Running the container as non-root user
By default, this container will not run as root. A user ID should be provided using `--user` in the CLI, or specified in the compose file.

This was done in hopes of being compatible with Podman (rootless) - let me know if it works for you!


## Contributing
### Info
Contributions welcome! Open an issue and PR containing the changes you'd like to commit.

I'm also looking for ideas/alternative approaches to the broad permissions currently applied to Steam's application folder and .local folder within the image during build.


### Gotchas
#### Creativerse's binary immediately exits with no error
Creativerse's server binary will immediately exit if:
- Something is wrong with the permissions of a folder it's trying to access (the user's .local folder/Steam folder?)
- It's launched from a folder outside of the data directory
- `-worldId` is not provided to the binary


---


This repo is not associated with Playful, Corp., and does not redistribute any IP. Creativerse is a registered trademark of Playful, Corp. in the U.S. and other countries.
