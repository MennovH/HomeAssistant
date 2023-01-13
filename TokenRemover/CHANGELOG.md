#v1.0.2
- Added two ways of keeping and/or regaining access when an active refresh token has been removed. In case the user had checked the "Keep me logged in" checkbox, this could lead to unintended bans.
  1. TokenRemover will backup the current ip_bans.yaml file. For a minute after the Core has been restarted, TokenRemover will compare the current ip_bans.yaml file with the backup. When differences have been detected, TokenRemover will restore the backup, and restart the Core once more.
  2. Added the option to overrule the number of retention days, by also assessing the "last_used_at" parameter in the token details. If a token is older than the set retention days, but activated within the set activation days, the token will be spared.
- Added the configurable options "Don't remove active tokens", and "Number of activation days".


# v1.0.1
First functioning release. Tested on a Home Assistant Supervised installation (Docker containers in Raspberry Pi Debian 11).

# v1.0.0
Created something
