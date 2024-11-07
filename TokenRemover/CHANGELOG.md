# v1.0.6
Spanish translation added by @sheaur

# v1.0.5
Additional code by @nbetcher to prevent crash on missing last_used_at info

# v1.0.4
Disabled AppArmor (temporarily?) due to issues connecting with the Supervisor.

# v1.0.3
- The following options have been added:
  - `keep_active`: If enabled, TokenRemover won't remove tokens which have been activated within the number of `activation_days`.
  - `activation_days`: TokenRemover won't remove tokens that have been activated within this number of days. Even when the token is significantly older than the set number of `retention_days`.
  - Recurrency with time (AM|PM|Both) and days
  - Updated documentation

# v1.0.2
- Added two ways of keeping and/or regaining access when an active refresh token has been removed. In case the user had checked the "Keep me logged in" checkbox, this could lead to unintended bans.
  1. TokenRemover will backup the current ip_bans.yaml file. For a minute after the Core has been restarted, TokenRemover will compare the current ip_bans.yaml file with the backup. When differences have been detected, TokenRemover will restore the backup, and restart the Core once more.
  2. Added the option to overrule the number of retention days, by also assessing the "last_used_at" parameter in the token details. If a token is older than the set retention days, but activated within the set activation days, the token will be spared.
- Added the configurable options "Don't remove active tokens", and "Number of activation days". To run only once, set the value to false on each day.


# v1.0.1
First functioning release. Tested on a Home Assistant Supervised installation (Docker containers in Raspberry Pi Debian 11).

# v1.0.0
Created something
