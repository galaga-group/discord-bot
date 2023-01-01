import os
import asyncio
import debugpy
import discord
from galaga_group_bot_data import galaga_group_bot_data
debugpy.listen(('0.0.0.0', 5678))
#debugpy.wait_for_client()
print('Hello, world!')

class galaga_group_bot(discord.Client):
    data: galaga_group_bot_data

    def __init__(self, data: galaga_group_bot_data, *args, **kwargs):
        super().__init__(*args, **kwargs)
        self.data = data


async def main():
    # Create the data layer
    data = await galaga_group_bot_data.create(
        host=       os.environ['GGB_DB_HOST'],
        database=   os.environ['GGB_DB_DATABASE'],
        user=       os.environ['GGB_DB_USER'],
        password=   os.environ['GGB_DB_PASSWORD'])

    # To respond to specific message content, we require message_content intent
    intents = discord.Intents.default()
    intents.message_content = True

    # Initialize and run the bot
    client = galaga_group_bot(data, intents = intents)
    client.run(os.environ['GGB_DISCORD_TOKEN'])

    return

asyncio.run(main())