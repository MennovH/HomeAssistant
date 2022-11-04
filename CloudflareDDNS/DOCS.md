# CloudflareDDNS Home Assistant add-on
Home Assistant add-on for Cloudflare DDNS.
Automatically update your A records via Home Assistant, every x minutes.
The add-on uses the Cloudflare API possibilities, which are free to use.
Using this add-on as extension to Nginx Proxy Manager, provides an easy way to circumvent the need of add-ons like DuckDNS, so you would be able to use your own domain. Even for your Home Assistant.

## Prerequisites
- Home Assistant Supervisor
- A valid Cloudflare account
  - The email address associated to this account needs to be added in the configuration of this add-on later on
- Cloudflare managed DNS records
  - The regarding domain name records must be managed via Cloudflare.
- A valid Cloudflare API token
  - Navigate to your online Cloudflare account (Account → My Profile → {} API Tokens)
  - Click on "Create Token"
  - Click on the "Use template" button behind the label "Edit zone DNS"
    - Optionally: rename the token
  - Leave the Permissions for what they are
  - Select the Specific zone(s) for which this token may be used
  - Leave the other options for what they are
  - Click on "Continue to summary"
  - Click on "Create Token" and store this token in a safe place(!), this also needs to be added to the configuration of this add-on later on
    - NOTE: when you leave this page, you can no longer retrieve this token via the web page. You would then need to create a new token.
- A Cloudflare Zone ID
  - The Zone ID of the regarding domain, is a long string which can be found in the lower right corner of the Cloudflare online dashboard Overview page, under the heading "API".

# Installation

1. In Home Assistant, navigate to settings → Add-ons, and click on the button labeled "ADD-ON STORE"
2. Click on the ⋮ in the top right corner → Repositories
3. Add this repository by filling in `https://github.com/MennovH/CloudflareDDNS`
4. When added, look up the add-on in the add-on overview. Select the add-on and press "Install". The add-on should be available for configuration in a short while.

# Configuration

When installed, navigate to the configuration tab of the add-on. Fill in the empty input fields according the instructions below.
1. `email_address` (required) Enter the e-mail address which is used for the Cloudflare portal.
2. `cloudflare_zone_id` (required) Enter the ZONE-ID for the zone of which the DNS records must be kept up-to-date.
3. `cloudflare_api_token` (required) Enter the API token with which you may edit DNS records for the specified zone.
4. `domains` (required) Add the (sub)domains of which the A records must be kept up-to-date.
5. `interval` (required) Enter an integer value between 1 and 1440 (default: 15). This is the interval in minutes in which the (sub)domains will be updated.
6. When ready, start the add-on. The logging will show its results. Don't forget to enable "Start at startup" and "Watchdog", to ensure the add-on is running.

## Example logging result

The following image shows an example output of the add-on, which can be found in the logbook. In this scenario, the A record of (sub)domain-3 pointed to a wrong IP address. The add-on found that this record was incorrect, and updated it accordingly. This change is instantly visible in the Cloudflare dashboard.

![CloudflareDDNS example logging][screenshot]

[screenshot]: https://raw.githubusercontent.com/MennovH/HomeAssistant/CloudflareDDNS/main/images/screenshot.png
