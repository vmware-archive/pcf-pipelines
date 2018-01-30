# Firewall rules for pipeline resources
**In order to leverage the resources used in our pipelines you might have to add firewall whitelist rules**
**Below you will find guidance for some of the more common resource implementations**

## Github
- Add the following CIDR to a whitelist in your firewall: `192.30.252.0/22`
- A github maintained list of IP Ranges for github can be found here:  `https://help.github.com/articles/github-s-ip-addresses/`

## S3 / CloudFront / AWS
**The following is an example of how to pull and curate a list of IP ranges direct from Amazon**

```
# get ip ranges json file from aws authority
$ wget https://ip-ranges.amazonaws.com/ip-ranges.json
# get cloudfront IPs
$ cat ip-ranges.json | jq -c '.prefixes | .[] | select( .service | contains("CLOUDFRONT"))'
# get s3 ips
$ cat ip-ranges.json | jq -c '.prefixes | .[] | select( .service | contains("S3"))'
```

- Updated list authority can be found here: `https://ip-ranges.amazonaws.com/ip-ranges.json`


## Pivnet
**The pivnet resource will need access to both the pivnet API and Amazon CloudFront access**

#### CloudFront Domains:
- `dtb5pzswcit1e.cloudfront.net`
- `d13k9s5899twdr.cloudfront.net`

#### Pivnet API
- `https://network.pivotal.io`

## Docker
**Docker hub does not provide a set of IPs so one must whitelist on domain**
- `*.docker.io`
- `docker-images-prod.s3.amazonaws.com`
