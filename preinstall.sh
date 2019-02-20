#!/bin/sh

# HOME_DIR is the absolute path to folder containing this script
HOME_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# We are being consumed by another repo. Let's copy scripts to root of repo for easy access.
if [[ $HOME_DIR =~ 'node_modules' ]]; then
    # When consumed by another repo, REPO_DIR is the absolute path to root of the consuming repo
    REPO_DIR="$(cd "$(dirname "$(cd "$(dirname "$HOME_DIR")" && pwd)")" && pwd)"

    DockerScripts="createDockerImg.sh installDockerImg.sh"
    scriptList=($DockerScripts)
    GitIgnoreFile=.gitignore

    for script in ${scriptList[@]}; do
        echo cp $HOME_DIR/$script $REPO_DIR
        cp $HOME_DIR/$script $REPO_DIR

        # add docker scripts to .gitignore in consuming repo
        GIT_IGNORE_OK=`head $REPO_DIR/$GitIgnoreFile | grep $script`
        if [[ -z $GIT_IGNORE_OK ]]; then
            echo adding $script to $REPO_DIR/$GitIgnoreFile
            sed -i '' -e '1s/^/'$script'\'$'\n/' "$REPO_DIR/$GitIgnoreFile"
        fi
    done
fi

echo installing git client side hooks...
$HOME_DIR/githooks/installhooks.sh