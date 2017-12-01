#!/bin/bash

# docker binary
DockerBinary=`which docker`

if [ ! -f $DockerBinary ]; then
    echo $DockerBinary is not installed on the system...
    exit 1
fi

#
# usage: script usage
#
usage() {
    echo `basename $0`: ERROR: $* 1>&2
    echo usage: `basename $0` 'docker_image [prod|staging|qa|local]' 1>&2
    exit 1
}

DockerImageFilename=$1
BuildEnv=$2

[ $# -ne 2 ] && usage "incorrect number of arguments"

if [ ! -z $DockerImageFilename ]; then
    echo $DockerImageFilename does not exist...
    exit 1
fi

if [ ! -z `echo $DockerImageFilename | grep .gz` ]; then
    fileExt='.image.gz'
else
    fileExt='.image'
fi

DockerImagePrefix='auto_bld'
DockerImageName=${DockerImageFilename%-*}
DockerImageTagName=`basename ${DockerImageFilename#*-} $fileExt`
BuildType=${DockerImageName#*$DockerImagePrefix}

#
# Functions
#

#
RemoveContainer() {
    # back up IFS
    LocalBakIFS=$IFS

    IFS=$OIFS

    #
    # CONTAINER ID|IMAGE|COMMAND|CREATED|STATUS|PORTS|NAMES

    # stop and remove container

    # restore IFS
    IFS=$LocalBakIFS
}

#
# Do execution
#
