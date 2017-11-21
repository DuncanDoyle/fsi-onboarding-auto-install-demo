#!/bin/sh 

DOCKER_MAJOR_VER=17
DOCKER_MINOR_VER=06
OC_MAJOR_VER="v3"
OC_MINOR_VER=6
OC_MINI_VER=173
OCP_VERSION="$OC_MAJOR_VER.$OC_MINOR_VER"
ISO_URL="https://github.com/boot2docker/boot2docker/releases/download/v1.13.1/boot2docker.iso"
ISO_CACHE="file://$HOME/.docker/machine/cache/boot2docker.iso"
VIRT_DRIVER="virtualbox"
STREAM_JBOSS="https://raw.githubusercontent.com/openshift/openshift-ansible/master/roles/openshift_examples/files/examples/v3.6/xpaas-streams/jboss-image-streams.json"
STREAM_FUSE="https://raw.githubusercontent.com/openshift/openshift-ansible/master/roles/openshift_examples/files/examples/v3.6/xpaas-streams/fis-image-streams.json"
STREAM_RHEL="https://raw.githubusercontent.com/openshift/openshift-ansible/master/roles/openshift_examples/files/examples/v1.4/image-streams/image-streams-rhel7.json"
STREAM_DOTNET="https://raw.githubusercontent.com/openshift/openshift-ansible/master/roles/openshift_examples/files/examples/v3.6/image-streams/dotnet_imagestreams.json"
TEMPLATE_EAP="https://raw.githubusercontent.com/openshift/openshift-ansible/master/roles/openshift_examples/files/examples/v3.6/xpaas-templates/eap70-basic-s2i.json"
TEMPLATE_BRMS_63="https://raw.githubusercontent.com/openshift/openshift-ansible/master/roles/openshift_examples/files/examples/v3.6/xpaas-templates/decisionserver63-basic-s2i.json"
TEMPLATE_BRMS_64="https://raw.githubusercontent.com/openshift/openshift-ansible/master/roles/openshift_examples/files/examples/v3.6/xpaas-templates/decisionserver64-basic-s2i.json"
TEMPLATE_BPMS_64_POSTGRESQL="https://raw.githubusercontent.com/openshift/openshift-ansible/master/roles/openshift_examples/files/examples/v3.6/xpaas-templates/processserver64-postgresql-s2i.json"

# uncomment amount memory needed, sets RAM usage limit for OCP, default 6 GB.
#VM_MEMORY=10240    # 10GB
VM_MEMORY=8192    # 8GB
#VM_MEMORY=6144     # 6GB
#VM_MEMORY=3072     # 3GB

# wipe screen.
clear 

echo
echo "##############################################################"
echo "##                                                          ##"   
echo "##  Setting up your very own                                ##"
echo "##                                                          ##"   
echo "##    ###  ####  ##### #   #  #### #   # ##### ##### #####  ##"
echo "##   #   # #   # #     ##  # #     #   #   #   #       #    ##"
echo "##   #   # ####  ###   # # #  ###  #####   #   ####    #    ##"
echo "##   #   # #     #     #  ##     # #   #   #   #       #    ##"
echo "##    ###  #     ##### #   # ####  #   # ##### #       #    ##"
echo "##                                                          ##"   
echo "##    ####  ###  #   # #####  ###  ##### #   # ##### #####  ##"
echo "##   #     #   # ##  #   #   #   #   #   ##  # #     #   #  ##"
echo "##   #     #   # # # #   #   #####   #   # # # ###   #####  ##"
echo "##   #     #   # #  ##   #   #   #   #   #  ## #     #  #   ##"
echo "##    ####  ###  #   #   #   #   # ##### #   # ##### #   #  ##"
echo "##                                                          ##"   
echo "##      ####  #      ###  ##### #####  ###  ##### #   #     ##"   
echo "##      #   # #     #   #   #   #     #   # #   # ## ##     ##"   
echo "##      ####  #     #####   #   ####  #   # ##### # # #     ##"   
echo "##      #     #     #   #   #   #     #   # #  #  #   #     ##"   
echo "##      #     ##### #   #   #   #      ###  #   # #   #     ##"   
echo "##                                                          ##"   
echo "##  https://github.com/redhatdemocentral/ocp-install-demo   ##"
echo "##                                                          ##"   
echo "##############################################################"
echo


# Remove demo Git repo
echo "Removing old 'FSI Client Onboarding Demo' Git repository."
echo
rm -rf fsi-onboarding-template/


# Ensure VirtualBox available.
#
if [ `uname` == 'Darwin' ]; then
		command -v VirtualBox -h >/dev/null 2>&1 || { echo >&2 "VirtualBox is required but not installed yet... download here: https://www.virtualbox.org/wiki/Downloads"; exit 1; }
		echo "VirtualBox is installed..."
		echo
elif [ `uname` == 'Linux' ]; then
		VIRT_DRIVER='kvm'
    echo "You are running on Linux."
    echo "This script assumes you are going to use KVM on Linux."
    echo "You'll need to install docker-machine and docker-machine-driver-kvm in your \$PATH manually."
    echo "Download them from https://github.com/docker/machine/releases and https://github.com/dhiltgen/docker-machine-kvm/releases, respectively."
fi

# Ensure docker engine available.
#
if [ `uname` == 'Darwin' ]; then
		command -v docker -h  >/dev/null 2>&1 || { echo >&2 "Docker is required but not installed yet... download here: https://store.docker.com/search?offering=community&type=edition"; exit 1; }
		echo "Docker is installed... checking for valid version..."
		echo
elif [ `uname` == 'Linux' ]; then
		command -v docker -h  >/dev/null 2>&1 || { echo >&2 "Docker is required but not installed yet... download here: https://store.docker.com/search?offering=community&type=edition or install through your distro's package manager"; exit 1; }
		echo "Docker is installed... checking for valid version..."
		echo
fi

# Check that docker deamon is setup correctly.
if [ `uname` == 'Darwin' ]; then
	# for osX.
	docker ps >/dev/null 2>&1

	if [ $? -ne 0 ]; then
		echo "Docker deamon is not running... please start Docker for osX..."
		echo
		exit
	fi
else
	# For some Linux versions, docker needs root permissions.
	echo "Checking the docker version on Linux requires 'sudo', please provide the password..."
	echo
	sudo docker ps >/dev/null 2>&1

	if [ $? -ne 0 ]; then
		echo "Docker deamon is not running... or is running insecurely..."
		echo
		echo "Check for instructions to run the docker deamon securely in NOTES section of this projects Readme.md file."
		echo
		exit
	fi
fi

echo "Verified the Docker daemon is running..."
echo

# Check docker engine version.
if [ `uname` == 'Darwin' ]; then
		dockerverone=$(docker version -f='{{ .Client.Version }}' | awk -F[=.] '{print $1}')
		dockervertwo=$(docker version -f='{{ .Client.Version }}' | awk -F[=.] '{print $2}')
		if [ $dockerverone -eq $DOCKER_MAJOR_VER ] && [ $dockervertwo -ge $DOCKER_MINOR_VER ]; then
			echo "Valid version of docker engine found... $dockerverone.$dockervertwo"
			echo
		else
			echo "Docker engine version $dockerverone.$dockervertwo found... need $DOCKER_MAJOR_VER.$DOCKER_MINOR_VER or higher, please install: https://store.docker.com/search?offering=community&type=edition"
			echo
			exit
		fi
elif [ `uname` == 'Linux' ]; then
		echo "This demo has been tested with docker 1.12+ on several Linux distro's, as various distro's"
		echo "ship with different versions of docker, not all available docker versions have been tested."
		echo "As such, the demo probably works with other versions of docker installed locally, but you run"
		echo "them at your own risk."
    echo
fi

# Ensure OpenShift command line tools available.
#
command -v oc help >/dev/null 2>&1 || { echo >&2 "OpenShift CLI tooling is required but not installed yet... download $OCP_VERSION here: https://access.redhat.com/downloads/content/290"; exit 1; }
echo "OpenShift command line tools installed... checking for valid version..."
echo

# Check oc version.
verfull=$(oc version | awk '/oc/{print $2}')
verone=$(echo $verfull | awk -F[=.] '{print $1}')
vertwo=$(echo $verfull | awk -F[=.] '{print $2}')
verthree=$(echo $verfull | awk -F[=.] '{print $3}')

# Check version elements, first is a string so using '==', the rest are integers.
if [ $verone == $OC_MAJOR_VER ] && [ $vertwo -eq $OC_MINOR_VER ] && [ $verthree -ge $OC_MINI_VER ]; then
	echo "Version of installed OpenShift command line tools correct... $verone.$vertwo.$verthree"
	echo
else
	echo "Version of installed OpenShift command line tools is $verone.$vertwo.$verthree, must be $OC_MAJOR_VER.$OC_MINOR_VER.$OC_MINI_VER..."
	echo
	if [ `uname` == 'Darwin' ]; then
		echo "Download for Mac here: https://access.redhat.com/downloads/content/290"
		exit
	else
		echo "Download for Linux here: https://access.redhat.com/downloads/content/290/"
		exit
	fi
fi

echo "Setting up OpenShift docker machine..."
echo
docker-machine create --driver ${VIRT_DRIVER} --${VIRT_DRIVER}-cpu-count "2" --${VIRT_DRIVER}-memory "$VM_MEMORY" --engine-insecure-registry 172.30.0.0/16 --${VIRT_DRIVER}-boot2docker-url $ISO_CACHE openshift 

if [ $? -ne 0 ]; then
		echo
		echo "Error occurred during openshift docker machine creation..."
		echo
		echo "Cleaning out existing 'openshift' machine..."
		echo
		docker-machine rm -f openshift

		echo "Setting up new OpenShift docker machine..."
    echo
    docker-machine create --driver ${VIRT_DRIVER} --${VIRT_DRIVER}-cpu-count "2" --${VIRT_DRIVER}-memory "$VM_MEMORY" --engine-insecure-registry 172.30.0.0/16 --${VIRT_DRIVER}-boot2docker-url $ISO_URL openshift 

		if [ $? -ne 0 ]; then
				echo
				echo "Problem with docker machine creation that I can't resolve, please raise an issue and add error output:"
				echo
				echo "   https://github.com/redhatdemocentral/ocp-install-demo/issues/new"
				echo
				exit
		fi
fi

echo "Installing OCP with cluster up..."
echo
oc cluster up --image=registry.access.redhat.com/openshift3/ose --host-data-dir=/var/lib/boot2docker/ocp-data --docker-machine=openshift --host-config-dir=/var/lib/boot2docker/ocp-config --use-existing-config=true --version=$OCP_VERSION --host-pv-dir=/var/lib/boot2docker/ocp-pv --service-catalog


if [ $? -ne 0 ]; then
		echo
		echo "Error occurred during 'oc cluster up' command..."
		echo
		echo "Cleaning out existing 'openshift' machine..."
		echo
		docker-machine rm -f openshift

    echo "Setting up new OpenShift docker machine..."
    echo
    docker-machine create --driver ${VIRT_DRIVER} --${VIRT_DRIVER}-cpu-count "2" --${VIRT_DRIVER}-memory "$VM_MEMORY" --engine-insecure-registry 172.30.0.0/16 --${VIRT_DRIVER}-boot2docker-url="$ISO_URL" openshift 

		echo
		echo "Trying again to install OCP with cluster up..."
		echo
		echo "Using osX version of cluster up... installing second try OCP version: $OCP_VERSION"
		echo
    oc cluster up --image=registry.access.redhat.com/openshift3/ose --host-data-dir=/var/lib/boot2docker/ocp-data --docker-machine=openshift --host-config-dir=/var/lib/boot2docker/ocp-config --use-existing-config=true --version=$OCP_VERSION --host-pv-dir=/var/lib/boot2docker/ocp-pv --service-catalog

		if [ $? -ne 0 ]; then
				echo
				echo "Problem with installation that I can't resolve, please raise an issue and add error output:"
				echo
				echo "   https://github.com/redhatdemocentral/ocp-install-demo/issues/new"
				echo
				exit
		fi
fi

echo
echo "Logging in as admin user..."
echo
oc login -u system:admin

# capturing OCP IP address from status command.
OCP_IP=$(oc status | awk '/My Project/{print $8}')

echo 
echo "Set OCP IP to $OCP_IP..."
echo

# set console environment to openshift container.
eval "$(docker-machine env openshift)"

echo "Granting admin user full cluster-admin rights..."
echo
oc adm policy add-cluster-role-to-user cluster-admin admin

if [ $? -ne 0 ]; then
	echo
	echo "Problem granting admin user full cluster-admin rights!"
	echo
	exit
fi

echo
echo "Granting rights to service catalog access..."
echo
oc adm policy add-cluster-role-to-group system:openshift:templateservicebroker-client system:unauthenticated system:authenticated

if [ $? -ne 0 ]; then
	echo
	echo "Problem granting service catalog rights!"
	echo
	exit
fi

echo
echo "Updating JBoss image streams..."
echo
oc delete -n openshift -f $STREAM_JBOSS >/dev/null 2>&1
oc create -n openshift -f $STREAM_JBOSS

if [ $? -ne 0 ]; then
	echo
	echo "Problem with accessing JBoss product streams for OCP..."
	echo
  echo "Trying again..."
	echo
	sleep 10
  oc delete -n openshift -f $STREAM_JBOSS >/dev/null 2>&1
  oc create -n openshift -f $STREAM_JBOSS
	
	if [ $? -ne 0 ]; then
		echo "Failed again, exiting, check output messages and network connectivity before running install again..."
		echo
		docker-machine rm -f openshift
		exit
	fi
fi

echo
echo "Updating Fuse image streams..."
echo
oc delete -n openshift -f $STREAM_FUSE >/dev/null 2>&1
oc create -n openshift -f $STREAM_FUSE

if [ $? -ne 0 ]; then
	echo
	echo "Problem with accessing Fuse Integration product streams for OCP..."
	echo
  echo "Trying again..."
	echo
	sleep 10
  oc delete -n openshift -f $STREAM_FUSE >/dev/null 2>&1
  oc create -n openshift -f $STREAM_FUSE
	
	if [ $? -ne 0 ]; then
		echo "Failed again, exiting, check output messages and network connectivity before running install again..."
		echo
		docker-machine rm -f openshift
		exit
	fi
fi

echo
echo "Updating EAP templates..."
echo
oc delete -n openshift -f $TEMPLATE_EAP >/dev/null 2>&1
oc create -n openshift -f $TEMPLATE_EAP

if [ $? -ne 0 ]; then
	echo
	echo "Problem with accessing JBoss EAP product streams for OCP..."
	echo
  echo "Trying again..."
	echo
	sleep 10
	oc delete -n openshift -f $TEMPLATE_EAP >/dev/null 2>&1
  oc create -n openshift -f $TEMPLATE_EAP
	
	if [ $? -ne 0 ]; then
		echo "Failed again, exiting, check output messages and network connectivity before running install again..."
		echo
		docker-machine rm -f openshift
		exit
	fi
fi

echo
echo "Updating Decision Server templates..."
echo
oc delete -n openshift -f $TEMPLATE_BRMS_63 >/dev/null 2>&1
oc delete -n openshift -f $TEMPLATE_BRMS_64 >/dev/null 2>&1
oc create -n openshift -f $TEMPLATE_BRMS_63
oc create -n openshift -f $TEMPLATE_BRMS_64

if [ $? -ne 0 ]; then
	echo
	echo "Problem with accessing JBoss BRMS product streams for OCP..."
	echo
  echo "Trying again..."
	echo
	sleep 10
  oc delete -n openshift -f $TEMPLATE_BRMS_63 >/dev/null 2>&1
  oc delete -n openshift -f $TEMPLATE_BRMS_64 >/dev/null 2>&1
  oc create -n openshift -f $TEMPLATE_BRMS_63
  oc create -n openshift -f $TEMPLATE_BRMS_64
	
	if [ $? -ne 0 ]; then
		echo "Failed again, exiting, check output messages and network connectivity before running install again..."
		echo
		docker-machine rm -f openshift
		exit
	fi
fi

TEMPLATE_BPMS_64_POSTGRESQL
echo
echo "Updating Process Server templates..."
echo
oc delete -n openshift -f $TEMPLATE_BPMS_64_POSTGRESQL >/dev/null 2>&1
oc create -n openshift -f $TEMPLATE_BPMS_64_POSTGRESQL

if [ $? -ne 0 ]; then
        echo
        echo "Problem with accessing JBoss BPM Suite product streams for OCP..."
        echo
  echo "Trying again..."
        echo
        sleep 10
  oc delete -n openshift -f $TEMPLATE_BPMS_64_POSTGRESQL >/dev/null 2>&1
  oc create -n openshift -f $TEMPLATE_BPMS_64_POSTGRESQL

        if [ $? -ne 0 ]; then
                echo "Failed again, exiting, check output messages and network connectivity before running install again..."
                echo
                docker-machine rm -f openshift
                exit
        fi
fi

echo
echo "Updating RHEL 7 image streams..."
echo
oc delete -n openshift -f $STREAM_RHEL >/dev/null 2>&1
oc create -n openshift -f $STREAM_RHEL

if [ $? -ne 0 ]; then
	echo
	echo "Problem with accessing RHEL product streams for OCP..."
	echo
  echo "Trying again..."
	echo
	sleep 10
  oc delete -n openshift -f $STREAM_RHEL >/dev/null 2>&1
  oc create -n openshift -f $STREAM_RHEL
	
	if [ $? -ne 0 ]; then
		echo "Failed again, exiting, check output messages and network connectivity before running install again..."
		echo
		docker-machine rm -f openshift
		exit
	fi
fi

echo
echo "Update .Net image streams..."
echo
oc delete -n openshift -f $STREAM_DOTNET >/dev/null 2>&1
oc create -n openshift -f $STREAM_DOTNET

if [ $? -ne 0 ]; then
	echo
	echo "Problem with accessing .Net image streams for OCP..."
	echo
  echo "Trying again..."
	echo
	sleep 10
  oc delete -n openshift -f $STREAM_DOTNET >/dev/null 2>&1
  oc create -n openshift -f $STREAM_DOTNET
	
	if [ $? -ne 0 ]; then
		echo "Failed again, exiting, check output messages and network connectivity before running install again..."
		echo
		docker-machine rm -f openshift
		exit
	fi
fi

echo
echo "FSI Onboarding Demo Project..."
echo

oc login -u openshift-dev -p devel

git clone https://github.com/entando/fsi-onboarding-template
pushd fsi-onboarding-template/openshift
./provision.sh setup client-onboarding
popd

echo
echo "===================================================="
echo "=                                                  ="
echo "= Install complete, FSI Onboarding Demo deployed.  ="
echo "=                                                  ="
echo "=  The server is accessible via web console at:    ="
echo "=                                                  ="
echo "=	  $OCP_IP              ="
echo "=                                                  ="
echo "=  Log in as user: openshift-dev                   ="
echo "=        password: devel                           ="
echo "=                                                  ="
echo "=  Admin log in as: admin                          ="
echo "=         password: admin                          ="
echo "=                                                  ="
echo "=  To stop and restart your OCP cluster with       ="
echo "=  installed containers, see Readme.md in the      ="
echo "=  NOTES section for details.                      ="
echo "=                                                  ="
echo "=  When finished, clean up your demo with:         ="
echo "=                                                  ="
echo "=     $ docker-machine rm -f openshift             ="
echo "=                                                  ="
echo "===================================================="
