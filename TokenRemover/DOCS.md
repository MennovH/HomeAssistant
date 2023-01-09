# TokenRemover Home Assistant add-on
Home Assistant add-on to remove old refresh tokens.
Using this add-on would mitigate the hassle you need to go through, if you want to clear the list with old refresh tokens. Every time you log in to Home Assistant, a refresh token will be created for that specified device.

## Prerequisites
- Home Assistant Supervisor

# Installation

1. In Home Assistant, navigate to settings → Add-ons, and click on the button labeled "ADD-ON STORE"
2. Click on the ⋮ in the top right corner → Repositories
3. Add this repository by filling in `https://github.com/MennovH/HomeAssistant`
4. When added, look up the add-on in the add-on overview. Select the add-on and press "Install". The add-on should be available for configuration in a short while.

# Configuration

When installed, navigate to the configuration tab of the add-on. Fill in the empty input fields according the instructions below.
1. `day` (required) Enter an integer value between 1 and 1440 (default: 7). Refresh tokens older than this number in days will be removed.
2. When ready, start the add-on.

#### Note1: when refresh tokens - older than the defined number of days (+30 minutes to prevent an onstartup retrigger of this add-on) - are found, Home Assistant core will be restarted. This step is necessary in order to make the changes permanent. You may want to run this add-on once in a while, e.g. with a nightly automation.

#### Note2: TokenRemover will update the auth file, which resides in the config/.storage directory. However, when an inactive device becomes active while TokenRemover is running, Home Assistant will restore the auth file from its cache. This shouldn't be much of an issue, because the timing must be right to achieve this. It is recommended to run this add-on when Home Assistant is not used much.

## Examle TokenRemover logging output
The following images show example outputs of the add-on, which can be found in the logbook.

Tokens older than 7 days (in this case) were found and removed from the file. It also shows that Home Assistant Core is restarting.
<br></br>
![example logging output][screenshot1]
<br><br>
<br><br>
When Home Assistant Core has been restarted, the logging output of TokenRemover shows the execution is done.
<br></br>
![example logging output][screenshot2]
<br><br>
<br><br>
Home Assistant Core will not undergo a restart, when no older tokens have been found to be removed.
<br></br>
![example logging output][screenshot3]
<br><br>
<br><br>
The above mentioned restart might kick in early, which would result in an error. This issue will clear itself, while it still gets the job done.
<br></br>
![example logging output][screenshot4]

[screenshot1]: https://raw.githubusercontent.com/MennovH/HomeAssistant/main/TokenRemover/images/example_log1.JPG
[screenshot2]: https://raw.githubusercontent.com/MennovH/HomeAssistant/main/TokenRemover/images/example_log2.JPG
[screenshot3]: https://raw.githubusercontent.com/MennovH/HomeAssistant/main/TokenRemover/images/example_log3.JPG
[screenshot4]: https://raw.githubusercontent.com/MennovH/HomeAssistant/main/TokenRemover/images/example_log4.JPG
