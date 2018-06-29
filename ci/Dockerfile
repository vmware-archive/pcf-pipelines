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

COPY terraforming-azure/ /home/vcap/app/terraforming-azure

RUN \
cp /usr/local/bin/yaml_patch_linux /usr/local/bin/yaml-patch && \
\
# gcloud SDK
export CLOUD_SDK_REPO="cloud-sdk-$(lsb_release -c -s)" && \
echo "deb http://packages.cloud.google.com/apt $CLOUD_SDK_REPO main" | sudo tee /etc/apt/sources.list.d/google-cloud-sdk.list && \
curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add - && \
apt-get -y update && sudo apt-get -y install --no-install-recommends google-cloud-sdk && \
\
# pip
apt-get install -y --no-install-recommends python-pip python-dev software-properties-common python-software-properties && \
\
# vim
ln -s /usr/bin/vim.tiny /usr/local/bin/vim && \
\
# UAA Client
gem install cf-uaac --no-ri --no-rdoc && \
\
# Ensure latest version of six
pip install six --upgrade && \
\
# AWS Client
pip install awscli && \
\
# Openstack Client
apt-get install -y --no-install-recommends libffi-dev && \
cat >> /tmp/requirements.txt <<EOF\
Babel==2.5.3\
PyYAML==3.12\
appdirs==1.4.3\
argparse==1.2.1\
asn1crypto==0.24.0\
awscli==1.14.66\
botocore==1.9.19\
bzr==2.7.0dev1\
certifi==2018.1.18\
cffi==1.11.5\
chardet==3.0.4\
cliff==2.11.0\
cmd2==0.8.2\
colorama==0.2.5\
configobj==4.7.2\
contextlib2==0.5.5\
cryptography==2.0.3\
debtcollector==1.19.0\
decorator==4.2.1\
deprecation==2.0\
docutils==0.14\
dogpile.cache==0.6.5\
enum34==1.1.6\
funcsigs==1.0.2\
functools32==3.2.3-2\
futures==3.2.0\
html5lib==0.999\
idna==2.6\
ipaddress==1.0.19\
iso8601==0.1.12\
jmespath==0.9.3\
jsonpatch==1.21\
jsonpointer==2.0\
jsonschema==2.6.0\
keystoneauth1==3.4.0\
mercurial==2.8.2\
monotonic==1.4\
msgpack==0.5.6\
munch==2.2.0\
netaddr==0.7.19\
netifaces==0.10.6\
openstacksdk==0.12.0\
os-client-config==1.29.0\
os-service-types==1.2.0\
osc-lib==1.10.0\
oslo.config==6.0.0\
oslo.i18n==3.20.0\
oslo.serialization==2.25.0\
oslo.utils==3.36.0\
packaging==17.1\
pbr==4.0.0\
prettytable==0.7.2\
pyOpenSSL==17.4.0\
pyasn1==0.4.2\
pycparser==2.18\
pycurl==7.19.3\
pyparsing==2.2.0\
pyperclip==1.6.0\
python-apt==0.9.3.5ubuntu2\
python-cinderclient==3.5.0\
python-dateutil==2.6.1\
python-glanceclient==2.9.1\
python-keystoneclient==3.15.0\
python-neutronclient==6.7.0\
python-novaclient==10.1.0\
python-openstackclient==3.14.0\
pytz==2018.3\
requests==2.18.4\
requestsexceptions==1.4.0\
rfc3986==1.1.0\
rsa==3.4.2\
s3transfer==0.1.13\
simplejson==3.13.2\
six==1.11.0\
stevedore==1.28.0\
subprocess32==3.2.7\
unicodecsv==0.14.1\
urllib3==1.22\
warlock==1.3.0\
wrapt==1.10.11\
wsgiref==0.1.2\
EOF && \
pip install -r /tmp/requirements.txt && \

# Azure Client
echo "deb https://packages.microsoft.com/repos/azure-cli/ wheezy main" | sudo tee /etc/apt/sources.list.d/azure-cli.list && \
curl -L https://packages.microsoft.com/keys/microsoft.asc | sudo apt-key add - && \
sudo apt-get -y install --no-install-recommends apt-transport-https && \
sudo apt-get -y update && sudo apt-get -y install --no-install-recommends azure-cli && \
\
# Clean up
apt-get remove -y python-dev apt-transport-https && \
apt-get -y clean && apt-get -y autoremove --purge && rm -rf /etc/apt/ && \
rm -rf /tmp/* && \
find /var/lib/apt/lists -type f | xargs rm -f && \
find /var/cache/debconf -type f -name '*-old' | xargs rm -f && \
find /var/log -type f -user root | xargs rm -rf && \
for file in $(find /var/log -type f -user syslog); do echo > $file; done
