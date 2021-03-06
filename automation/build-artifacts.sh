#!/bin/bash -xe

ROOT_PATH=$PWD

# remove any previous artifacts
rm -rf ../ovirt-build ../rhv-build
rm -f ./*tar.gz

# Create paths for builds
mkdir -p ../ovirt-build ../rhv-build
# Create builds

./build.sh build ovirt ../ovirt-build
./build.sh build rhv ../rhv-build

cd ../ovirt-build
# create the src.rpm
rpmbuild \
    -D "_srcrpmdir $PWD/output" \
    -D "_topmdir $PWD/rpmbuild" \
    -ts ./*.gz

# install any build requirements
yum-builddep output/*src.rpm

# create tar for galaxy
ansible-galaxy collection build

# create the rpms
rpmbuild \
    -D "_rpmdir $PWD/output" \
    -D "_topmdir $PWD/rpmbuild" \
    --rebuild output/*.src.rpm

cd ../rhv-build

# create tar for automation hub
ansible-galaxy collection build

# Store any relevant artifacts in exported-artifacts for the ci system to
# archive
[[ -d exported-artifacts ]] || mkdir -p $ROOT_PATH/exported-artifacts $ROOT_PATH/exported-artifacts/

find ../ovirt-build/output -iname \*rpm -exec mv "{}" $ROOT_PATH/exported-artifacts/ \;
mv ../ovirt-build/*tar.gz $ROOT_PATH/exported-artifacts/

mv ../rhv-build/*tar.gz $ROOT_PATH/exported-artifacts/

COLLECTION_DIR="/usr/local/share/ansible/collections/ansible_collections/ovirt/ovirt"
mkdir -p $COLLECTION_DIR
cp -r ../ovirt-build/* $COLLECTION_DIR
cd $COLLECTION_DIR

pip3 install rstcheck antsibull-changelog ansible-lint

ansible-test sanity
/usr/local/bin/antsibull-changelog lint
/usr/local/bin/ansible-lint roles/* -x 204

cd $ROOT_PATH
