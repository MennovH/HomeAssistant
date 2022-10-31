# CloudflareDDNS
Home Assistant add-on for Cloudflare DDNS.
Automatically update your A records via Home Assistant, every x minutes.
The add-on uses the Cloudflare API possibilities, which are free to use.
Using this add-on as extension to Nginx Proxy Manager, provides an easy way to circumvent the need of add-ons like DuckDNS, so you would be able to use your own domain names. Even for your Home Assistant.

## Prerequisites
- Home Assistant Supervisor
- A valid Cloudflare account
- Cloudflare managed DNS records
  - The regarding domain name records must be managed via Cloudflare.
- Cloudflare API token
  - In your online Cloudflare account, create an API token for the regarding zone, which allows the DNS records to be modified.
- Cloudflare zone ID
  - The zone ID can be found in the DNS section of the online Cloudflare dashboard

## Example logging result

![CloudflareDDNS example logging](images/screenshot.png)
