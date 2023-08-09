# v2.0.1
- Fixed issue in which the add-on would crash when no A record can be retrieved from Cloudflare (either due to missing A records, or API retrieval issue)
- Updated error handling
- Currently disabled AppArmor to prevent curl issues from occurring
- Added auth parameter which has no meaning for the add-on other than increasing the security rating :)

# v2.0.0
- Fixed public IP (PIP) retrieval issues
  - Added secondary API for redundancy to retrieve the PIP
  - Added infinite while loop with delay to ensure that the iteration only starts when the current PIP is known
  - Added error handling to prevent the add-on to crash in case the PIP could not be retrieved
- Fixed startup error message by removing deprecated parameters
- Improved logging
  - Added log message that shows how many domains (returned by API and persistent config) need to be iterated
  - Added log message to see which API was used (shown only when "Log public IP address" configuration is set to true)
  - Added status counters which shows changes [a/b/c] in green and errors [d/e/f/g] in red:
    - a: number of times PIP has changed
    - b: successful A record creations
    - c: successful A record updates
    - d: failed attempts retrieving PIP by APIs
    - e: failed iterations
    - f: failed A record creations 
    - g: failed A record updates
  - Added colored bullets to represent the proxy status that match Cloudflare's definitions (orange cloud = proxied, grey cloud = not proxied)
    - At this moment the cloud icon colors only seem to be visible in the Desktop app. For this reason these icons are not (yet) used as bullets.
  - Replaced "created" log messsage with plus sign
  - Replaced "updated" log message with reload/refresh symbol
- Changed configuration key "hide_public_ip" to "log_pip"
  - Old configuration "hide_public_ip" can be removed as the double negative was confusing
  - New configuration "log_pip" has default value of "true"
- Removed unnecessary code
- Updated documentation and images

# v1.3.7
- Added error counters to logs.
- Small changes to code.

# v1.3.6
- Removed the e-mail address configuration, as it was not necessary for the Cloudflare API. This removal has no impact for installations with the e-mail address still defined in the configuration file.
- Added visibility to each domain's proxy status in the logs, regardless of whether the PIP is configured as hidden.
- Added comments to code.
- Updated documentation and images.

# v1.3.5
- Fixed "missing domains" issue, by correcting the config.yaml file of this add-on. Users without any configuration were forced to use the code editor and make (minor) changes to get the add-on to work properly.
- Added validation to prevent the add-on to crash. In some occasions it was found that the add-on failed to obtain the domains via Cloudflare API. When iterating this empty list of domains, the add-on wasn't able to restore itself and crashed.
- Minor deletions of old code.

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
