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
- Cloudflare API token
  - Navigate to your online Cloudflare account (Account → My Profile → {} API Tokens)
  - Create a Custom Token
    - Give the API token a descriptive name
    - Recommended permissions for this API token, select:
      - "Zone", "DNS", "Edit", respectively
      - Leave the other options as is
    - Create and save(!) the token, this needs to be added to the configuration of this add-on later on
- Cloudflare Zone ID
  - The Zone ID of the regarding domain, can be found in the lower right corner of the Cloudflare online dashboard Overview page, under the heading "API".

#### Please consult the documentation for installation and configuration of this add-on

## Example logging result

The following example shows an output of the add-on, where the A record of (sub)domain-3 pointed to a wrong IP address. The add-on found this record was incorrect, and updated it accordingly. This change is instantly visible in the Cloudflare dashboard.

![CloudflareDDNS example logging][screenshot]

[screenshot]: https://raw.githubusercontent.com/MennovH/CloudflareDDNS/main/images/screenshot.png
