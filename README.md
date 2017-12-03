# README
When consumed by another repo, preinstall will copy docker related scripts to root of the consuming repo, and run a script to enable 2 git client side hooks.


## createDockerImg.sh
Bash script to create docker image from a docker file, and export the image with timestamp as tag for uniqueness.

## installDockerImg.sh
Bash script to install docker image. It will remove the followings:
1) all dangling docker images and their associated containers.
2) all unused docker images.
3) given the docker image and the targeted environment, all docker images of the sanme image name and their associated containers.

## githooks
1) 2 git client side hooks
2) sample git client side hooks
