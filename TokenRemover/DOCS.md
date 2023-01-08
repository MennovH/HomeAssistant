# CloudflareDDNS Home Assistant add-on
Home Assistant add-on to remove old refresh tokens.
Using this add-on would mitigate the hassle you need to go through, if you want to clear the list with old refresh tokens. Every time you log in to Home Assistant, a refresh token will be created for that specified device.

## Prerequisites
- Home Assistant Supervisor

# Installation

1. In Home Assistant, navigate to settings → Add-ons, and click on the button labeled "ADD-ON STORE"
2. Click on the ⋮ in the top right corner → Repositories
3. Add this repository by filling in `https://github.com/MennovH/TokenRemover`
4. When added, look up the add-on in the add-on overview. Select the add-on and press "Install". The add-on should be available for configuration in a short while.

# Configuration

When installed, navigate to the configuration tab of the add-on. Fill in the empty input fields according the instructions below.
1. `hour` (required) Select the hour on which the add-on should check for old refresh tokens.
2. `quarter` (required) Select the quarter of the hour on which the add-on should check for old refresh tokens.
3. `day` (required) Enter an integer value between 1 and 1440 (default: 7). Refresh tokens older than this number in days will be removed.
4. When ready, start the add-on.
