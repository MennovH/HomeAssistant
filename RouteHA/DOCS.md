# CloudflareDDNS Home Assistant add-on
Home Assistant add-on for periodically push the desired routes to the HA instance.

## Prerequisites
- Home Assistant Supervisor

# Installation

1. In Home Assistant, navigate to settings → Add-ons, and click on the button labeled "ADD-ON STORE"
2. Click on the ⋮ in the top right corner → Repositories
3. Add this repository by filling in `https://github.com/MennovH/HomeAssistant`
4. When added, look up the add-on in the add-on overview. Select the add-on and press "Install". The add-on should be available for configuration in a short while.

# Configuration

When installed, navigate to the configuration tab of the add-on. Fill in the empty input fields according the instructions below.
1. `default_route` (required) Enter the ZONE-ID for the zone of which the DNS records must be kept up-to-date.
2. `static_routes` (required) Enter the API token with which you may edit DNS records for the specified zone.
3. `interval` (required) Enter an integer value between 1 and 1440 (default: 10). This is the interval in minutes in which the (sub)routes will be updated.
4. When ready, start the add-on. The logging will show its results. Don't forget to enable "Start at startup" and "Watchdog", to ensure the add-on is running.
