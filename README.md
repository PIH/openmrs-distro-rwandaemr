openmrs-distro-rwandaemr
==========================

This project represents the OpenMRS RwandaEMR distribution as maintained by PIH / IMB.

# Layout and Variations

This project is set up as a monorepo that contains several distinct subprojects, each of which is deployed as a 
separate Maven artifact.  These subprojects are intended to represent the content and distribution configurations that
are shared across the country, and the content and distribution configurations that inherit from the shared artifacts
to represent the specific version installed in a particular server network or instance.

## rwandaemr-content

Shared content and configuration that is intended to be inherited by all downstream distributions.  Wherever possible,
all content additions and changes should be added to this project so that it can be included consistently across 
all implementations.

## rwandaemr-distro

Shared distribution that is intended to be the parent distribution of all downstream distributions.  Wherever possible,
any updates to core, modules, owas, and any other shared artifacts should be maintained here, so that consistent versions
are used across implementations.

## rwinkwavu-content, butaro-content, etc

Network or server-specific content packages, which are intended only for deployment to one or more servers.  For example,
certain locations or forms should only be deployed to particular instances, they would be placed in separate content projects.

## rwinwavu-distro, butaro-distro, etc

Network or server-specific distributions, which are intended only for deployment to one or more servers.
Typically, one of these distros would server to inherit from the `rwandaemr-distro`, include the `rwandaemr-content`
and a server-specific content package, and provide variables for any variables defined in the `rwandaemr-content` package.

### Variables

If there are instances where a particular piece of content should be _mostly_ the same, but contains minor variations that
can be represented with variables, then a variable syntax is supported.  One should follow the existing pattern.

* Add a new variable to the `./rwandaemr-content/content.properties` file with an empty value (eg. `var.oncologyLocation=`)
* In any file that contains variable content across distributions, replace the content with this variable name (eg. `${oncologyLocation}`
* In any downstream distribution that includes this content, add a value for this variable (eg. `var.oncologyLocation=Rwinkwavu Hospital`)

# Setting up a development environment with the OpenMRS SDK

First identify the distribution you want to set up.  There are currently 2 options:

* rwinkwavu
* butaro

## Prerequisites

* Java 8 (`sudo apt-get install openjdk-8-jdk`)
* Maven 3 (`sudo apt-get install maven`)
* MySQL 8 (either a native install or using Docker)
* OpenMRS SDK (see https://wiki.openmrs.org/display/docs/OpenMRS+SDK#OpenMRSSDK-Installation)

## Initial setup

The OpenMRS SDK allows you to have multiple "servers" installed.  It organizes each of these servers on your computer
as a subdirectory within an overall `~/openmrs` directory.

Each server must therefore be given a unique name.  This name will be the name of the directory under `~/openmrs` and 
will be used to identify the particular server of interest when running all SDK commands.

Good server names are concise and informative.  For example, if you are setting up an SDK server with a database backup from the
`rwinkwavu` facility, then a good server name for this would be `rwinkwavu`.

* Build this project using `mvn clean install`

* Determine which distribution variation you want to install.  First, find the `XXX-distro` folder that represents the
distro of interest.  For example, to set up a server for use in the Rwinkwavu network, find the `rwinkwavu-distro` folder.
Within this folder, locate the `pom.xml` file and locate the Maven coordinates.  These will be found in a section like this:

```xml
    <parent>
      <groupId>org.pih.openmrs</groupId>
      <artifactId>rwandaemr</artifactId>
      <version>3.2.0-SNAPSHOT</version>
    </parent>
    
    <artifactId>rwinkwavu-distro</artifactId>
    <packaging>jar</packaging>
```

The identifier for the distribution is constructed from components of the above as `groupId:artifactId:version`.
If no specific value for one of these is found, then the value from the `parent` element is used.  So for the example
shown here, the distribution identifier is:  `org.pih.openmrs:rwinkwavu-distro:3.2.0-SNAPSHOT`

* Set up a server using this distribution identifier:  `mvn openmrs-sdk:setup -DserverId=<server_id> -Ddistro=<distro_identifier>`

For example, to set up a distribution for Rwinwavu as shown above into an SDK server named `rwinktest`, you would run a command like:

```mvn openmrs-sdk:setup -DserverId=rwinktest -Ddistro=org.pih.openmrs:rwinkwavu-distro:3.2.0-SNAPSHOT```

You would then follow the remaining prompts to set up the server with:
* Appropriate Tomcat Port (8080 recommended)
* Appropriate Debugger Port (5000 recommended)
* Appropriate database and java home configurations.

## Ongoing updates

As a distribution changes over time - either by updating core, module, and other artifact versions in the distro project(s)
or by updating configurations in the content project(s), you will want to update your local SDK environment with these changes.
To do this:

* Identify which distribution variation you are installing.  For example, if your SDK server was set up with the `rwinkwavu-distro` then the variation is `rwinkwavu`
* Identify the server name that you want to update (eg. in the example above, it was named `rwinktest`)
* Run the `./install.sh` script using:  `./install.sh <variation> <server>`.  For example:  `./install.sh rwinkwavu rwinktest`

If you are only working on a small aspect of configuration, you can also often copy files directly into your SDK and use 
the administrative tools to refresh your server, for more rapid testing.  

For example, if you are editing new message properties in the rwandaemr-content package, you can get these to appear 
in an SDK server named `rwinktest` without rebuilding and restarting as follows:

```
cp -r rwandaemr-content/backend_configuration/messageproperties/* ~/openmrs/rwinktest/configuration/messageproperties/
```

Then, navigate to http://localhost:8080/openmrs/rwandaemr/admin/configuration.page and click "Refresh Message Properties"

Similarly, if you are editing appframework configuration files, you can update these without rebuilding and restarting as follows:

`cp -r rwandaemr-content/backend_configuration/appframework/* ~/openmrs/rwinktest/configuration/appframework/`

Then, navigate to http://localhost:8080/openmrs/rwandaemr/admin/configuration.page and click "Refresh Apps and Extensions"

### Other versions and historical documentation

This project is currently distinct from the Rwanda EMR distribution and configuration artifacts here:
https://github.com/Rwanda-EMR/openmrs-distro-rwandaemr
https://github.com/Rwanda-EMR/openmrs-config-rwandaemr
However, ideally the above projects would be rekindled using the content and configuration found in this project, and
the contents of `./rwandaemr-content` and `./rwandaemr-distro` could be migrated to these appropriately.

Early documentation for this project which is no longer current [can be found here](https://github.com/PIH/openmrs-distro-rwandaemr/wiki).
