FROM cloudfoundry/cflinuxfs2

COPY \
       om-linux \
       semver-linux \
       yaml_patch_linux \
       cf \
       cliaas-linux \
       pivnet-cli \
       govc \
       stemcell-downloader \
       steamroll \
       jq \
       terraform \
       /usr/local/bin/

RUN \
cp /usr/local/bin/yaml_patch_linux /usr/local/bin/yaml-patch && \

# gcloud SDK
export CLOUD_SDK_REPO="cloud-sdk-$(lsb_release -c -s)" && \
echo "deb http://packages.cloud.google.com/apt $CLOUD_SDK_REPO main" | sudo tee /etc/apt/sources.list.d/google-cloud-sdk.list && \
curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add - && \
apt-get -y update && sudo apt-get -y install --no-install-recommends google-cloud-sdk && \

# pip
apt-get install -y --no-install-recommends python-pip python-dev && \

# vim
ln -s /usr/bin/vim.tiny /usr/local/bin/vim && \

# UAA Client
gem install cf-uaac --no-ri --no-rdoc && \

# Ensure latest version of six
pip install six --upgrade && \

# AWS Client
pip install awscli && \

# Openstack Client
apt-get install -y --no-install-recommends libffi-dev && \
pip install cryptography==2.0.3 pyOpenSSL==17.4.0 python-openstackclient pytz python-neutronclient && \

# Azure Client
echo "deb https://packages.microsoft.com/repos/azure-cli/ wheezy main" | sudo tee /etc/apt/sources.list.d/azure-cli.list && \
sudo apt-key adv --keyserver packages.microsoft.com --recv-keys 417A0893 && \
sudo apt-get -y install --no-install-recommends apt-transport-https && \
sudo apt-get -y update && sudo apt-get -y install --no-install-recommends azure-cli && \

# Clean up
apt-get remove -y python-dev apt-transport-https && \
apt-get -y clean && apt-get -y autoremove --purge && rm -rf /etc/apt/ && \
rm -rf /tmp/* && \
find /var/lib/apt/lists -type f | xargs rm -f && \
find /var/cache/debconf -type f -name '*-old' | xargs rm -f && \
find /var/log -type f -user root | xargs rm -rf && \
for file in $(find /var/log -type f -user syslog); do echo > $file; done
