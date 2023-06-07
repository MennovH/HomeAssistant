# CloudflareDDNS Home Assistant add-on
Home Assistant add-on for Cloudflare DDNS.
Automatically update your A records via Home Assistant, every x minutes.
The add-on uses the Cloudflare API possibilities, which are free to use.
Using this add-on as extension to Nginx Proxy Manager, provides an easy way to circumvent the need of add-ons like DuckDNS, so you would be able to use your own domain.

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

#### Please consult the documentation for installation and configuration of this add-on

## Example logging result

The following image shows an example output of the add-on, which can be found in the logbook. In this scenario, the A record of example3.com pointed to a wrong IP address. The add-on found that this record was incorrect, and updated it accordingly. Furthermore, the A record of example4.com was missing. The add-on in turn created the A record (proxied). These changes are instantly visible in the Cloudflare dashboard.

![CloudflareDDNS example logging output][screenshot]

[screenshot]: https://raw.githubusercontent.com/MennovH/HomeAssistant/main/CloudflareDDNS/images/example_log.png
