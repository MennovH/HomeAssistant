import asyncio
import json
import websockets

HA_WS_URL = "ws://127.0.0.1:8123/api/websocket"


async def revoke_tokens(long_lived_token, token_ids):
    async with websockets.connect(HA_WS_URL) as ws:

        await ws.recv()

        await ws.send(json.dumps({
            "type": "auth",
            "access_token": long_lived_token
        }))

        resp = json.loads(await ws.recv())
        if resp.get("type") != "auth_ok":
            raise Exception("Auth failed")

        results = []
        req_id = 1

        for token_id in token_ids:
            await ws.send(json.dumps({
                "id": req_id,
                "type": "auth/revoke",
                "refresh_token_id": token_id
            }))

            results.append(json.loads(await ws.recv()))
            req_id += 1

        return results