noms-factloader
===============

This package provides a ``factloader`` script that is used for batch
and on-demand loading of Puppet Facter_ facts into the NOMS_ CMDB.

.. _NOMS: http://github.com/evernote/noms-client/wiki

.. _Facter: http://puppetlabs.com/facter

Syntax
------

.. ::

   factloader { --factpath path | file } [file [...]]
      --nocheck-expiry  Don't check expiration date
      --factpath        Specify directory full of *.yaml files
      --trafficcontrol  Specify trafficcontrol parameter
         url=           Specify trafficcontrol URL
         username=      Specify trafficcontrol Username
         password=      Specify trafficcontrol password
      Other options as outlined in Optconfig
