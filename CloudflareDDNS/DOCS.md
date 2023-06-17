# CloudflareDDNS Home Assistant add-on
Home Assistant add-on for Cloudflare DDNS.
Automatically update your A records via Home Assistant, every x minutes.
The add-on uses the Cloudflare API possibilities, which are free to use.
Using this add-on as extension to Nginx Proxy Manager, provides an easy way to circumvent the need of add-ons like DuckDNS, so you would be able to use your own domain. Even for your Home Assistant.

## Prerequisites
- Home Assistant Supervisor
- A valid Cloudflare account
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
3. Add this repository by filling in `https://github.com/MennovH/HomeAssistant`
4. When added, look up the add-on in the add-on overview. Select the add-on and press "Install". The add-on should be available for configuration in a short while.

# Configuration

When installed, navigate to the configuration tab of the add-on. Fill in the empty input fields according the instructions below.
1. `cloudflare_zone_id` (required) Enter the ZONE-ID for the zone of which the DNS records must be kept up-to-date.
2. `cloudflare_api_token` (required) Enter the API token with which you may edit DNS records for the specified zone.
3. `domains` (optional) Add the (sub)domains of which A records must exist. This feature will create the A records when they are missing in the portal (e.g. deleted by mistake). All current (sub)domains will be fetched with each run. Each (sub)domain must be added separately (see example configuration below). All A records will be created as "proxied" by default. When specific (sub)domains should not be proxied, add the string "_no_proxy" directly behind the regarding (sub)domains.
4. `interval` (required) Enter an integer value between 1 and 1440 (default: 10). This is the interval in minutes in which the (sub)domains will be updated.
5. When ready, start the add-on. The logging will show its results. Don't forget to enable "Start at startup" and "Watchdog", to ensure the add-on is running.

It's also possible to directly configure the add-on via the YAML configurator, as shown in the image below.
<br></br>
![example YAML configuration][screenshot2]

## Example CloudflareDDNS logging output
The image below shows a full example output of the add-on, which can be found in the logbook. To hide the PIP information, set the "Log public IP address" option to false.
<br></br>
![example logging output][screenshot3]

### Updates
The log shows there were two iterations. The A record of example1.com and later of example3.com, pointed to a wrong IP address. The add-on found that these records were incorrect, and updated them accordingly via the Cloudflare API. These changes are directly visible in the Cloudflare dashboard.
### Creations
The add-on also noticed that the A record of example7.com (which was manually configured as persistent domain (see example configuration)) was missing during the first iteration, and created it via the Cloudflare API. This change is directly visible in the Cloudflare dashboard.
### Bullet points
The colors of the bullet points represent the proxy status of the regarding A record and match the orange and grey cloud definitions of Cloudflare. Orange means the A record is proxied by Cloudflare. When you look up a proxied domain, it will resolve to Cloudflare and thus hide your PIP. Grey on the other hand, means that the A record resolves to your PIP. At the moment the phone app doesn't show the color of orange cloud icons. This is why the clouds themselves are not (yet) used as bullet points.
### Status
The status shows the past changes [green] and errors [red]. Every value divided by a "/" has its own meaning as explained below.
#### Runtime changes
- First value: shows the number of times the PIP has changed since the add-on started
- Second value: shows the number of A records created by the add-on since the add-on started
- Last value: shows the number of A records updated by the add-on since the add-on started
#### Runtime errors
- First value: counter for failing to get the current public IP address (possible causes: API failure, network issues)
- Second value: counter for failing during an iteration (possible causes: Cloudflare API failure, network issues)
- Third value: counter for failing to create an A record (possible causes: Cloudflare API failure, misconfigurations)
- Last value: counter for failing to update an A record (possible cause: Cloudflare API failure)

[screenshot1]: https://raw.githubusercontent.com/MennovH/HomeAssistant/main/CloudflareDDNS/images/example_domain_list.png
[screenshot2]: https://raw.githubusercontent.com/MennovH/HomeAssistant/main/CloudflareDDNS/images/example_yaml.png
[screenshot3]: https://raw.githubusercontent.com/MennovH/HomeAssistant/main/CloudflareDDNS/images/example_log.png
