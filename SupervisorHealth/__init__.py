"""Provides Supervisor Health."""

from .const import DOMAIN
import aiohttp
import asyncio
from datetime import timedelta
from homeassistant.config_entries import ConfigEntry
from homeassistant.core import callback, HomeAssistant
from homeassistant.helpers.discovery import async_load_platform
from homeassistant.helpers.update_coordinator import DataUpdateCoordinator, UpdateFailed
import logging

_LOGGER = logging.getLogger(__name__)


async def async_setup(hass: HomeAssistant, config: dict):
    """Setup from configuration.yaml."""
    _LOGGER.debug("async_setup")
    return True


async def async_setup_entry(hass: HomeAssistant, entry: ConfigEntry):
    """Setup from Config Flow Result."""
    _LOGGER.debug("async_setup_entry")

    coordinator = HealthUpdateCoordinator(
        hass,
        _LOGGER,
        update_interval=timedelta(seconds=10)
    )
    await coordinator.async_refresh()

    hass.data[DOMAIN] = {
        "coordinator": coordinator
    }

    hass.async_create_task(async_load_platform(hass, "sensor", DOMAIN, {}, entry))
    return True


class HealthUpdateCoordinator(DataUpdateCoordinator):
    """Update handler."""

    def __init__(self, hass, logger, update_interval=None):
        """Initialize global data updater."""
        logger.debug("__init__")

        super().__init__(
            hass,
            logger,
            name=DOMAIN,
            update_interval=update_interval,
            update_method=self._async_update_data,
        )

    async def _async_update_data(self):
        """Fetch health."""
        self.logger.debug("_async_update_data")
        url = 'http://localhost:4357'
        try:
            async with aiohttp.ClientSession() as session:
                async with session.get(url) as resp:
                    text = await resp.text().split('\n')
                    #res = text.split('\n')
                    return {'supervisor_health': ", ".join([text[i].strip() \
                            for i in range(len(text)) \
                            if '<' not in text[i] \
                            and len(res[i].strip()) > 4 \
                            and ':' not in text[i]])}
        except Exception as e:
            return {'supervisor_health': f'{e}'}
