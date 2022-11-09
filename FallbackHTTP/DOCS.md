# FallbackHTTP Home Assistant add-on
Home Assistant add-on for FallbackHTTP.


## Prerequisites
- 

# Installation

1. In Home Assistant, navigate to settings → Add-ons, and click on the button labeled "ADD-ON STORE"
2. Click on the ⋮ in the top right corner → Repositories
3. Add this repository by filling in `https://github.com/MennovH/FallbackHTTP`
4. When added, look up the add-on in the add-on overview. Select the add-on and press "Install". The add-on should be available for configuration in a short while. A page refresh may be needed when done.

# Configuration

When installed, navigate to the configuration tab of the add-on. Fill in the empty input fields according the instructions below.
1. `interval` (required) Enter an integer value between 1 and 1440 (default: 15). This is the interval in minutes in which the HTTPS connectivity will be tested.

It's also possible to directly configure the add-on via the YAML configurator, as shown in the image below.
<br></br>
![example YAML configuration][screenshot1]

## Examle FallbackHTTP logging output
The following image shows an example output of the add-on, which can be found in its logbook.
<br></br>
![example logging output][screenshot2]

[screenshot2]: https://raw.githubusercontent.com/MennovH/HomeAssistant/main/FallbackHTTP/images/example_yaml.png
[screenshot3]: https://raw.githubusercontent.com/MennovH/HomeAssistant/main/FallbackHTTP/images/example_log.png
