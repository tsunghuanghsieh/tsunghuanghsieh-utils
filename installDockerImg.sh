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
    echo -e `basename $0`: "\033[41m\033[30mERROR\033[0m" $* 1>&2
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

# this script expects docker image and tag name in specific format.
# confirm value of build type before continuing.
if expr $BuildType != 'server' > /dev/null && expr $BuildType != 'client' > /dev/null; then
    echo $DockerImageFilename does not have the expected naming format
    echo Please install $DockerImageFilename manually
    exit 0
fi

DockerRunArgs=''
if expr $BuildType = 'server' > /dev/null; then
    # If reverse proxy is used, we will need to set environment variables for docker container
    # VirtualHost=''
    # VirtualPort=''
    # DockerRunArgs=$DockerRunArgs' -e VIRTUAL_HOST'$VirtualHost
    # DockerRunArgs=$DockerRunArgs' -e VIRTUAL_PORT'$VirtualPort
fi

if expr $BuildType = 'client' > /dev/null; then
    # If reverse proxy is used, we will need to set environment variables for docker container
    # VirtualHost=''
    # DockerRunArgs=$DockerRunArgs' -e VIRTUAL_HOST'$VirtualHost
fi

#
RemoveContainer() {
    # back up internal field separator (IFS)
    PreviousIFS=$IFS

    IFS=$OriginalIFS

    # 7 columns in `docker ps` output
    # CONTAINER ID|IMAGE|COMMAND|CREATED|STATUS|PORTS|NAMES
    containerCols=($1)
    containerColsCount=${#containerCols[@]}
    echo container name ${containerCols[$containerColsCount-1]} id ${containerCols[0]}

    # stop and remove container
    if [[ $container =~ "Up" ]]; then
        echo stopping container ${containerCols[$containerColsCount-1]}...
        $DockerBinary stop ${containerCols[$containerColsCount-1]} > /dev/null
    else
        echo container ${containerCols[$containerColsCount-1]} is not running...
    fi
    echo removing container ${containerCols[$containerColsCount-1]}...
    $DockerBinary rm ${containerCols[$containerColsCount-1]} > /dev/null

    # restore IFS
    IFS=$PreviousIFS
}

#
# DO WORK
#

echo Build type is $BuildType
echo Build environment is $BuildEnv
echo Docker image name is $DockerImageName
echo Docker image tag name is $DockerImageTagName

# if docker image is gzipped, unzip it
if expr $fileExt = '.image.gz' > /dev/null; then
    echo unzipping $DockerImageFilename...
    gunzip $DockerImageFilename

    # strip .gz from filename
    DockerImageFilename=`basename $DockerImageFilename .gz`

    echo
fi

declare -a imagesPendingDeletion

# back up default internal field separator (IFS)
OriginalIFS=$IFS

# When a docker image with running container(s) is forcefully removed
# using `docker rmi -f image_id`
# the image is dangling, with its associated containers.
# Those container, if not removed, may cause name conflicts later.
# So, we should remove all dangling images and their associated containers.
danglingList=`$DockerBinary images --filter dangling=true -q`
if [[ ! -z $danglingList ]]; then
    # set IFS for splitting the list of docker images
    IFS=$'\n'
    danglings=($danglingList)
    for dangling in ${danglings[@]}; do
        echo dangling image id $dangling
        containerList=`$DockerBinary ps -f ancestor=$dangling | grep $dangling`
        # set IFS for splitting the list of docker containers
        IFS=$'\n'
        containers=($containerList)
        for container in ${containers[@]}; do
            RemoveContainer $container
        done
        echo removing dangling image $dangling...
        $DockerBinary rmi -f $dangling
    done
fi

imageList=`$DockerBinary images | grep $DockerImageName`
# set IFS for splitting the list of docker images
IFS=$'\n'
images=($imageList)
for image in ${images[@]}; do
    # restore IFS to default for splitting docker image columns
    IFS=$OriginalIFS
    imageCols=($image)

    # 5 columns in `docker image` output
    # REPOSITORY|TAG|IMAGE ID|CREATED|SIZE

    # find all related containers
    containerList=`$DockerBinary ps -a | grep ${imageCols[0]}:${imageCols[1]}`
    if [[ -z $containerList ]]; then
        echo
        echo removing unused image ${imageCols[0]}:${imageCols[1]} id ${imageCols[2]}...
        $DockerBinary rmi -f ${imageCols[0]}:${imageCols[1]}
    fi
done

# find all containers for the targeted environment and build type
containerList=`$DockerBinary ps -a | grep $BuildEnv.$BuildType`
if [[ ! -z $containerList ]]; then
    echo
    # set IFS for splitting the list of docker containers
    IFS=$'\n'
    containers=($containerList)
    for container in ${containers[@]}; do
        RemoveContainer $container

        # restore IFS to default for splitting docker container columns
        IFS=$OriginalIFS
        # 7 columns in `docker ps` output
        # CONTAINER ID|IMAGE|COMMAND|CREATED|STATUS|PORTS|NAMES
        containerCols=($container)
        containerColsCount=${#containerCols[@]}

        imageInUse=`$DockerBinary ps -a | grep ${containerCols[1]}`
        # if image does not have any container, add it to the list for removal
        if [[ -z $imageInUse ]]; then
            # verify if the image is already in the pending deletion list before adding
            if [[ ! "${imagesPendingDeletion[*]}" =~ ${containerCols[1]}]]; then
                echo image ${containerCols[1]} is no longer in use, pending deletion...
                imagesPendingDeletion[${#imagesPendingDeletion[@]}]=${containerCols[1]}
            fi
        fi
    done
fi

if [[ ${#imagesPendingDeletion[@]} -ne 0 ]]; then
    echo
fi

for image in ${imagesPendingDeletion[@]}; do
    if [[ ! -z `$DockerBinary images $image | grep $DockerImageName`]]; then
        echo removing image ${image}...
        $DockerBinary rmi -f ${image}
    else
        echo image ${image} was previously removed...
    fi
done

#restore IFS to the default value
IFS=$OriginalIFS

echo

# load docker image if it is not already loaded
if [[ -z `$DockerBinary images $DockerImageName:$DockerImageTagName | grep $DockerImageTagName`]]; then
    echo $DockerBinary load -i $DockerImageFilename
    $DockerBinary load -i $DockerImageFilename
else
    echo $DockerImageName:$DockerImageTagName is already loaded...
fi

# run docker container from image
echo $DockerBinary run --name $BuildEnv.$BuildType.$DockerImageName.$DockerImageTagName $DockerRunArgs -d $DockerImageName:$DockerImageTagName
$DockerBinary run --name $BuildEnv.$BuildType.$DockerImageName.$DockerImageTagName $DockerRunArgs -d $DockerImageName:$DockerImageTagName > /dev/null
