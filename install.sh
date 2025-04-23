#!/bin/bash

# Fail immediately if any of the steps result in an error
set -e

usage () {
    echo -e "Usage: install.sh [VARIATION] [SERVER]\n"
    echo -e "Installs the VARIATION (butaro or rwinkwavu) to a SERVER (the name of an OpenMRS SDK instance at path '~/openmrs/[SERVER]')\n"
    echo -e "Example: ./install.sh rwinkwavu rwinktest\n"
}

if [ $# -eq 0 ]; then
    echo -e "Please provide the variation and name of the server to install to as a command line argument.\n"
    usage
    exit 1
fi

VARIATION=$1
SERVER_ID=$2

echo "Building parent configuration"
mvn clean install -f ./rwandaemr-content/pom.xml

echo "Building parent distribution"
mvn clean install -f ./rwandaemr-distro/pom.xml

echo "Building ${VARIATION} configuration"
mvn clean install -f ./${VARIATION}-content/pom.xml

echo "Building ${VARIATION} distribution"
mvn clean install -f ./${VARIATION}-distro/pom.xml

echo "Deploying ${VARIATION} distribution to ${SERVER_ID}"
mvn openmrs-sdk:deploy -Ddistro=${VARIATION}-distro/target/distro/web/openmrs-distro.properties -DserverId=${SERVER_ID}

echo "Installation complete"