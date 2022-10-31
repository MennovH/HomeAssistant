# CloudflareDDNS
Home Assistant add-on for Cloudflare DDNS.
Automatically update your A records via Home Assistant, every x minutes.
The add-on uses the Cloudflare API possibilities, which are free to use.
Using this add-on as extension to Nginx Proxy Manager, provides an easy way to circumvent the need of add-ons like DuckDNS, so you would be able to use your own domain names. Even for your Home Assistant.

## Prerequisites
- Home Assistant Supervisor
- Valid Cloudflare account
- Cloudflare managed DNS records
  The regarding domain name records must be managed via Cloudflare.
- Cloudflare API token
  In your online Cloudflare account, create an API token for the regarding zone, which allows the DNS records to be modified.
- Cloudflare zone ID
  The zone ID can be found in the DNS section of the online Cloudflare dashboard

# Installation

1. In Home Assistant, navigate to settings → Add-ons, and click on the button labeled "ADD-ON STORE"
2. Click on the ⋮ in the top right corner → Repositories
3. Add this repository by filling in `https://github.com/MennovH/CloudflareDDNS`
4. When added, look up the add-on in the add-on overview. Select the add-on and press "Install". The add-on should be available for configuration in a short while.

# Configuration

1. `email_address` (required) Enter the e-mail address which is also used for the Cloudflare portal
2. `cloudflare_zone_id` (required) Enter the ZONE-ID for the zone of which you'd like the DNS records to be updated
3. `cloudflare_api_token` (required) Enter the API token with which you may read and edit DNS records for the specified zone
4. `domains` (required) Add the (sub)domains which should be updatedd
5. `interval` (required) Enter the interval in minutes in which the (sub)domains should be updated (default: 15)
6. When ready, start the add-on. The logging will show its results.

## Example logging result

Updating DDNS every 15 minutes
 
Time: 2022-10-31 21:27
Public IP address: xxx.xxx.xxx.xxx
Iterating domain list:
 - (sub)domain-1, up-to-date
 - (sub)domain-2, up-to-date
 - (sub)domain-3 (yyy.yyy.yyy.yyy), updated
 - (sub)domain-4, up-to-date
 
Waiting 15 minutes for next check...
