#!/bin/sh

# initializations
# HOME_DIR is the absolute path to the parent folder of this script
HOME_DIR="$( cd "$( dirname "$( dirname "$( dirname "$( dirname "${BASH_SOURCE[0]}")")")")" && pwd)"
# REPOHOOKS_DIR is the absolute path to the folder containing this script and all client side hooks
REPOHOOKS_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}")" && pwd)"
# GITHOOKS_DIR is the default folder in which git searches for client side hooks
GITHOOKS_DIR=$HOME_DIR/.git/hooks

# check for existence of default folder containing client side hooks
# the folder does not get created by 'git clone', it is created when running 'git init'
# let's create it if it's not already there
if [[ ! -d $GITHOOKS_DIR ]]; then
    echo Creating $GITHOOKS_DIR...
    mkdir $GITHOOKS_DIR
fi

# create symbolic links in git's default hooks folder to all hooks found in this folder
for hook in $(ls -A $REPOHOOKS_DIR); do
    if [[ "$REPOHOOKS_DIR/$hook" =~ $(basename ${BASH_SOURCE[0]}) ]]; then
        # skip this script file
        echo Skipping install script $hook
    elif [[ "$REPOHOOKS_DIR/$hook" =~ ".sample" ]]; then
        # skip all sample hook files
        echo Skipping sample hook $hook
    elif [[ -x "$REPOHOOKS_DIR/$hook" ]]; then
        echo ln -svf "$REPOHOOKS_DIR/$hook" "$GITHOOKS_DIR"
        ln -svf "$REPOHOOKS_DIR/$hook" "$GITHOOKS_DIR" > /dev/null
    else
        echo WARNING!!! Skipping "$REPOHOOKS_DIR/$hook". Not executable.
    fi
done
