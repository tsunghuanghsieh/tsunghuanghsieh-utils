#!/bin/bash

# docker binary
DockerBinary=`which docker`

if [ ! -f $DockerBinary ]; then
    echo $DockerBinary is not installed on the system...
    exit 1
fi

# initialize default values
BuildNumber=`date +%Y%m%d_%H%M%S`
BuildType='unknown'
DockerFileName='DockerFileName'
DockerImageName='auto_bld*'

#
# usage
#
usage() {
    echo `basename $0`: ERROR: $* 1>&2
    echo usage: `basename $0` '[server|client|clean]' 1>&2
    exit 1
}

[ $# -ne 1 ] && usage "incorrect number of arguments"

if [ $# -gt 0 ] && expr $1 = 'server' > /dev/null; then
    BuildType=$1
    DockerFileName='serverfile'
    DockerImageName='auto_bldserver'
elif [ $# -gt 0 ] && expr $1 = 'client' > /dev/null; then
    BuildType=$1
    DockerFileName='clientfile'
    DockerImageName='auto_bldclient'
else [ $# -gt 0 ] && expr $1 = 'clean' > /dev/null; then
    echo removing all docker images on disk...
    rm -rf $DockerImageName.image*
    exit 0
else
    usage "unknown argument"
fi

if [ ! -z $DockerFileName ]; then
    echo $DockerFileName does not exist...
    exit 1
fi

#
# DO WORK
#

echo Creating $BuildType docker image...
$DockerBinary build -t $DockerImageName:$BuildNumber -f $DockerFileName

echo Exporting $BuildType docker image to disk...
$DockerBinary save -o $DockerImageName-$BuildNumber.image $DockerImageName:$BuildNumber
