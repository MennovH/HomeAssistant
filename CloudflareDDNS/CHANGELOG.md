# v1.3.5
- Fixed "missing domains" issue, by correcting the configuration.yaml file. Users without any configuration were forced to use the code editor to get the add-on to work.

# v1.3.4
- Breaking change: Fixed the issue where the optional "(sub)domains" setting wasn't really optional because it required the key-value format.
  Update the current YAML config of the add-on like so:

  Old:<br>
  ``` domains:
    - domain: <domain1>
    - domain: <domain2>
    - domain: <...>
  ```
  
  New:<br>
  ``` domains:
    - <domain1>
    - <domain2>
    - <...>
  ```

  *This is how it originally was, until it suddenly didn't function properly during the lifetime of v1.2.0.*
  <br>
- Fixed PIP not being shown when disabling the "Hide PIP" option.
- With the "Hide PIP" option disabled, logging output will from now on also show whether or not the record is proxied by Cloudflare.
- Minor visual changes to the logging output.
- Updated documentation and images

# v1.3.3
- Removed the need to manually configure (sub)domains. CloudflareDDNS will fetch all existing A records within the specified zone and keep them up-to-date accordingly. - A records of manually configured (sub)domains will automatically be created when missing in the Cloudflare portal (proxied by default).
  - Added option to create non-proxied A records per (sub)domain, by adding the string "_no_proxy" directly behind the regarding (sub)domain.
- Minor logging output modifications.

# v1.3.2
- Improved domain sorting:
  - The log output will be available sooner while iterating through the list of domains
- Removed sort option from configuration:
  - The list of domains will be sorted by default
  - Any duplicates will from now on certainly be removed from the list
- Improved error handling:
  - Missing domains will now be mentioned in the logs
  - Missing domains won't cause the add-on to stop running anymore
  - Errors won't cause the add-on to stop running anymore

# v1.3.1
Updated codenotary

# v1.3.0 - breaking change
- Breaking change: domain configuration must be manually updated once. The previous configuration accepted lists, but since one of the last HA updates, the input field of the domains is no longer displayed.
  The UI expects a dictionary as of now.

  Update the current YAML config of the add-on like so:

  Old:<br>
  domains:
    - <domain1>
    - <domain2>
    - <...>

  New:<br>
  domains:
    - domain: <domain1>
    - domain: <domain2>
    - domain: <...>

- Breaking change: Renamed add-on slug to match the add-on name. This would require to reinstall the add-on. Copy your current YAML file before doing this, to
  reconfigure the add-on at ease.
- Added option to hide PIP in logbook, which is true by default.
- Added sort option to iterate through domains alphabetically. This option is enabled by default, and will also remove any duplicates.
- Added names and descriptions to the UI configuration menu, to improve its readability and to increase clarity.
- Added message to logbook, to display the moment on which the next DNS check will be.
- Removed message which displayed the waiting time (interval).
- Replaced logbook "up-to-date"-statements with check marks.
- Reduced privileges
  
# v1.2.0
- Removed ingress configuration, because it was not functional. This could be the reason why the add-on failed to work since the latest Home Assistant updates.
- Updated logging visuals
- Added README.md file to add-on
- Added CHANGELOG.md file to add-on
- Added logging example to README.md
