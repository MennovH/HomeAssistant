# HomeAssistant
Folder for Home Assistant add-ons
This repository contains self-created add-ons for Home Assistant.

## CloudflareDDNS
This add-on keeps your A records in Cloudflare up-to-date without any user interaction.
When using solutions like the Nginx Proxy Manager add-on, you can use your own domain to remotely access your (Home Assistant) instances.
This add-on requires you to manage your domain in Cloudflare as it is based on the Cloudflare API.
Orange cloud or grey cloud (i.e. proxied or not) is no problem for this add-on. It even allows you to specify domains for which A records (orange/grey) should be created when missing, to be sure these A records always exist.

## TokenRemover
Decide when access tokens need to be removed, so TokenRemover will delete these automatically when the thresholds have been met.
This allows for easier token removal without having to remove them per-user.

## supervisor_health
Custom integration which retrieves the supervisor status by using the Home Assistant api.
The integration needs manual installation, and can then be shown as entity in your dashboard.
