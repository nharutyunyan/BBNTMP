#!/bin/bash
#Builds a project from the command line

EXPECTED_ARGS=4
if [ $# -ne $EXPECTED_ARGS ]
then
  echo "Usage: $0 [path to ndk host] [project name] [signing keys password] [BuildId]"
  echo "ex: $0 \"/home/macuser/bbndk/host_10_0_10_536/linux/x86/usr/bin\" myApp password ${bamboo.buildNumber}"
  exit 1
fi

#We need this in order to have access to the commandline builder from momentics (platform specific...)
NDK_HOST=$1

# project name is directory under workspace for project to build
PROJECT=$2

# signing keys password
STOREPASS=$3

# package the app into a signed deployable bar file

echo CD to $PROJECT
cd $PROJECT

echo Set environment
. /opt/bbndk/bbndk-env.sh

echo "Make (clean)"
make clean

echo "Make (build Device-Release)"
make Device-Release

echo Package and sign the bar file
echo $NDK_HOST/blackberry-nativepackager -package $PROJECT.bar -configuration Device-Release -buildId $4 -sign -storepass $STOREPASS bar-descriptor.xml -C .
$NDK_HOST/blackberry-nativepackager -package $PROJECT.bar -configuration Device-Release -buildId $4 -sign -storepass $STOREPASS bar-descriptor.xml -C .
