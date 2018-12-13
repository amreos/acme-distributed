# acme-distributed
**acme-distributed** is a (still incomplete) command line ACME client for distributed certificate ordering. 

# Status
**acme-distributed** is work in progress. I use it as my primary ACME client for ordering and renewing all of my Let's Encrypt certificates so far. You are welcome to start using it as well. Please use the issue tracker to file bug reports.

**First things first:**

*  This documentation is quite **out of date** - sorry for that, I'm working on new documentation.
*  Only HTTP authorization requests are currently supported
*  You need an existing ACME account and private key, this client currently cannot create accounts (feature is on the roadmap, tho)

# Synopsis

    USAGE: ./acme-distributed.rb [options] <configuration>
      -V, --version                    Display version number and exit
      -e, --endpoint <name>            The endpoint to use for the request
      -c <cert1[, cert2[, ...]]>,      Certificates to request
         --certificates
      -L, --log-level <level>          Log level to use [DEBUG, INFO, WARN, ERROR]. Default is INFO.
      -r, --remaining-lifetime <days>  Only renew certificates which have a remaining validity less than <days> days
      -n, --dry-run                    Dry-run mode, does not perform any actual change.

# Description
**acme-distributed** is a simple ACME client for special use cases. It does not implement all functionality that other ACME clients offer. If you are just looking for an ordinary ACME client, please look elsewhere.

The corner case implemented by this client is the separation of certificate ordering from fullfilling http-01 authorization requests. This can be useful in the following scenarios:

* You can not have (or do not want) the ACME client on your web server(s) for whatever reasons
* Your webservers cannot initiate connections to the outside world
* You do not want your private account key on your web servers
* You want to centralize your Let's Encrypt certficate management and not have multiple hosts (i.e. your webservers) being responsible for that

Please note that **acme-distributed** will not (nor will ever) deploy any certificates to your servers. This task is left to whatever configuration management or provisioning tools you might have in place.

# Installation

* Clone the repository to a convinient location on your system
* Run ```bundler install``` to install dependencies

# How it works
Basically, what **acme-distributed** does is similar to other ACME clients when requesting certificates, except that it places the http-01 authorization challenges not on the local machine, but on each of the configured remote servers:

1. Place a new order for certificate generation with the ACME provider
2. For each configured challenge server, place the authorization challenge(s) generated by the ACME provider via SSH at the configured locations on the remote servers
3. Trigger authorization check(s) from ACME provider
4. Remove the authorization challenges created in (2) from each configured server
5. Evaluate the results of the authorization(s)
6. On success, create a CSR file for the requested certificates and send it to the ACME provider
7. Retrieve the signed certificates from the ACME provider and store them on the local filesystem

# Requirements
**acme-distributed** uses the Ruby ACME implementation [acme-client](https://github.com/unixcharles/acme-client) by Charles Barbier and requires

* Ruby 2.1 or higher
* The following ruby gems
  * acme-client
  * net-ssh
  
The host managing the certificates needs SSH access to the hosts serving the authorization requests. The only privilege required for the user is write access to the directory where the authorization requests are created.

Furthermore, you will need a Let's Encrypt account already setup, i.e. you need a valid, registered account key. **acme-distributed** does **not** offer registration functionality right now.

# Configuration
**acme-distributed** uses configuration files in simple YAML format. The following configurables are available:

## Endpoint configuration
Define the available ACME endpoints for this configuration.  

* **url** is the ACME API endpoint URL to use
* **private_key** refers to the account's private RSA key in PEM format. It must exist (i.e. you need to have setup an account before)

The **url** and **private_key** options are mandatory.

You can name the endpoints as you wish, the names **production** and **staging** below are just examples.

```yaml
endpoints:                                                                                                                                                                  
  production:                                                                                                                                                               
    url: https://acme-v02.api.letsencrypt.org/directory                                                                                                                     
    private_key: /etc/acme-deploy/accounts/production/private-key.pem                                                                                                       
    email_addr: certs@example.com
  staging:
    url: https://acme-staging-v02.api.letsencrypt.org/directory
    private_key: /etc/acme-deploy/accounts/staging/private-key.pem
    email_addr: certs@example.com
```
## Certificate configuration
You can define any number of certificates **acme-distributed** should handle. Each certificate needs a unique name name, which is given as the entry key.

* **subject** specifies the CN in the certificate's subject
* **key** specifies the (local) path to the private key used for generating the CSR and for the final certificate
* **path** specifies the (local) path the final certificate will be stored at in PEM format
* **san** specifies a list of additional DNS names the certificate shall be valid for
* **renew_days** renew certificate only if its lifetime is less than specified number of days (defaults to 30)

The options **subject**, **key** and **path** are mandatory.

You can use the special variable ```{{endpoint}}``` for the name of the endpoint in **key** and **path** values. If found, it will be replaced with the endpoint configuration name (e.g. **staging** or **production** if defined as in the example above).

```yaml
certificates:
  ssl.example.com:
    subject: ssl.example.com
    san:
      - ssl2.example.com
      - ssl3.example.com
    key: /etc/acme-deploy/{{endpoint}}/keys/ssl.example.com.key
    path: /etc/acme-deploy/{{endpoint}}/certs/ssl.example.com.pem

  secure.example.com:
    subject: secure.example.com
    key: /etc/acme-deploy/{{endpoint}}/keys/secure.example.com.key
    path: /etc/acme-deploy/{{endpoint}}/certs/secure.example.com.pem

```
## Connector configuration
The list of servers which will handle the http-01 authorization challenges are defined here. You can define any number of servers you wish, and you should define all servers here that will have the certificates deployed (e.g. those that will terminate SSL requests for the FQDNs specified in the configured certificates.)

* **hostname** specifies the DNS hostname (or IP address) of the server to connect to via SSH
* **username** specifies the remote username to use for authentication
* **ssh_port** specifies the TCP port the SSH daemon on the server listens to
* **acme_path** specifies the path on the remote server where authorization challenges are put

All settings above are mandatory. 

Please note that only the base name of the path sent by the ACME challenge will be used when creating the challenge files on the remote servers -- the ```/.well-known/acme``` part will be cut off. So you either have an alias configured on your web servers pointing to **acme_path** or you include ```/.well-known/acme``` in **acme_path** setting. In the example below, the web server is configured with an alias ```/.well-known/acme -> /var/www/acme``` for simplicity.

```yaml
challenge_servers:
  frontend_web_1:
    hostname: www1.example.com
    username: acme
    ssh_port: 22
    acme_path: /var/www/acme
  frontend_web_2:
    hostname: www2.example.com
    username: acme
    ssh_port: 22
    acme_path: /var/www/acme

```
# License & pull requests
**acme-distributed** is put in the Public Domain under the [Unlicense](http://www.unlicense.org) terms. 

Pull requests and patches are accepted as long as they are put in the public domain as well. For this purpose, please accompany your patches with the following statement:

```
I dedicate any and all copyright interest in this software to the
public domain. I make this dedication for the benefit of the public at
large and to the detriment of my heirs and successors. I intend this
dedication to be an overt act of relinquishment in perpetuity of all
present and future rights to this software under copyright law.
```
