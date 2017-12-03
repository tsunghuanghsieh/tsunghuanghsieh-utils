#!/bin/sh

# PARENT_DIR is the absolute path to the parent folder of this script
PARENT_DIR="$( cd "$( dirname "$( dirname "${BASH_SOURCE[0]}")")" && pwd)"

# We are being consumed by another repo. Let's copy scripts to root of repo for easy access.
if [[ $PARENT_DIR =~ 'node_modules' ]]; then
    # When consumed by another repo, HOME_DIR is the absolute path to root of the consuming repo
    HOME_DIR="$( cd "$( dirname "$( dirname "$PARENT_DIR")")" && pwd)"

    DockerScripts="createDockerImg.sh installDockerImg.sh"
    scriptList=($DockerScripts)
    GitIgnoreFile=.gitignore

    for script in ${scriptList[@]}; do
        echo cp $PARENT_DIR/$script $HOME_DIR
        cp $PARENT_DIR/$script $HOME_DIR

        # add installDockerImg.sh to .gitignore
        GIT_IGNORE_OK=`head $HOME_DIR/$GitIgnoreFile | grep $script`
        if [[ -z $GIT_IGNORE_OK ]]; then
            echo adding $script to $HOME_DIR/$GitIgnoreFile
            sed -i '' -e '1s/^/'$script'\'$'\n/' "$HOME_DIR/$GitIgnoreFile"
        fi
    done
fi


echo installing git client side hooks...
$PARENT_DIR/githooks/installhooks.sh