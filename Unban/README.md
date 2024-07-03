# Unban Home Assistant add-on
Home Assistant add-on to unban manually defined IPs from ip_bans.yaml file.
This add-on runs at set intervals to prevent yourself from being locked out from Home Assistant.

## Prerequisites
- Home Assistant Supervisor

# Installation

1. In Home Assistant, navigate to settings → Add-ons, and click on the button labeled "ADD-ON STORE"
2. Click on the ⋮ in the top right corner → Repositories
3. Add this repository by filling in `https://github.com/MennovH/HomeAssistant`
4. When added, look up the add-on in the add-on overview. Select the add-on and press "Install". The add-on should be available for configuration in a short while.

# Configuration

When installed, navigate to the configuration tab of the add-on. Fill in the empty input fields according the instructions below.
1. `ips` (required) Enter the IPs that must be removed from ip_bans.yaml file.
2. `interval` (required) Enter an integer value between 1 and 1440 (default: 10). This is the interval in minutes in which the (sub)domains will be updated.
3. When ready, start the add-on. The logging will show its results. Don't forget to enable "Start at startup" and "Watchdog", to ensure the add-on is running.

