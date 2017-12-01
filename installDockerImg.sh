#!/bin/bash

# docker binary
DockerBinary=`which docker`

#
# usage: script usage
#
usage() {
    echo `basename $0`: ERROR: $* 1>&2
    echo usage: `basename $0` 'docker_image [prod|staging|qa|local]' 1>&2
    exit 1
}

#
RemoveContainer() {
    BackupIFS=$IFS
}