# v1.3.0 - breaking change
- Breaking change: domain configuration must be manually updated once. The previous configuration accepted lists, but since one of the last HA updates, the input field of the domains is no longer displayed.
  The UI expects a dictionary as of now.

  Update the current YAML config of the add-on like so:

  Old:
  domains:
    - <domain1>
    - <domain2>
    - <...>

  New:
  domains:
    - domain: <domain1>
    - domain: <domain2>
    - domain: <...>

- Added option to hide PIP in logbook, which is true by default.
- Added sort option to iterate through domains alphabetically. This option is enabled by default, and will also remove any duplicates.
- Added names and descriptions to the UI configuration menu, to improve its readability and to increase clarity.
- Added message to logbook, to display the moment on which the next DNS check will be.
- Removed message which displayed the waiting time (interval).

# v1.2.0
- Removed ingress configuration, because it was not functional. This could be the reason why the add-on failed to work since the latest Home Assistant updates.
- Updated logging visuals
- Added README.md file to add-on
- Added CHANGELOG.md file to add-on
- Added logging example to README.md
