# v1.3.2
- Improved domain sorting
- Removed sort option:
  - All domains will be sorted by default
  - Any duplicates will now certainly be removed from the list
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
