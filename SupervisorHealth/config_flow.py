"""Config flow for Supervisor Health integration."""

from .const import DOMAIN
from homeassistant import config_entries

@config_entries.HANDLERS.register(DOMAIN)
class HealthFlowHandler(config_entries.ConfigFlow, domain=DOMAIN):
    """Handle a config flow for Supervisor Health."""

    VERSION = 1
    CONNECTION_CLASS = config_entries.CONN_CLASS_CLOUD_POLL

    async def async_step_user(self, user_input=None):
        """Show config Form step."""
        return self.async_create_entry(
            title="Supervisor Health",
            data={},
        )
