import os
import asyncio
import debugpy
import discord
from discord.ext import commands
import typing
from galaga_group_bot_data import galaga_group_bot_data
debugpy.listen(('0.0.0.0', 5678))
#debugpy.wait_for_client()
print('Hello, world!')

class galaga_group_bot(commands.Bot):
    data: galaga_group_bot_data

    def __init__(self, data: galaga_group_bot_data, *args, **kwargs):
        super().__init__(*args, **kwargs)
        self.data = data

    async def setup_hook(self) -> None:
        return

    async def lookup_or_register_user(self, author: discord.User | discord.Member):
        disc = int(author.discriminator)
        db_user = await self.data.lookup_user(author.id)
        if db_user == None:
            db_user = await self.data.register_user(author.id, author.name, author.display_name, disc)
        return db_user
    
    async def build_player_card_embed(self, db_user, author: discord.User | discord.Member) -> discord.Embed:
        embed = discord.Embed(
            title = 'Player Card',
            url = '',
            color = discord.Color.from_str('#252525'),
            description = ''
        )
        embed.set_author(name=author.display_name, icon_url=author.avatar.url)
        scores = await self.data.get_personal_best_scores(db_user['id'])
        for score in scores:
            embed.add_field(name = score['category'], value = '[{}]({})'.format(score['high_score'], score['evidence_link']), inline = True)
        return embed


async def main():
    async with await galaga_group_bot_data.create(
            host=       os.environ['GGB_DB_HOST'],
            database=   os.environ['GGB_DB_DATABASE'],
            user=       os.environ['GGB_DB_USER'],
            password=   os.environ['GGB_DB_PASSWORD']) as data:
        # To respond to specific message content, we require message_content intent
        intents = discord.Intents.default()
        intents.messages = True
        intents.message_content = True

        async with galaga_group_bot(data = data, command_prefix = '!', intents = intents) as bot:
            # Initialize and run the bot
    
            @bot.command()
            async def submit(ctx: commands.Context, category: str, score: int, evidence_link: typing.Optional[str]):
                db_user = await bot.lookup_or_register_user(ctx.author)
                await bot.data.do_submission(db_user['id'], category, score, evidence_link)
                await ctx.message.delete()
                # Build the embed
                embed = await bot.build_player_card_embed(db_user, ctx.author)
                await ctx.send(embed=embed)

            @bot.command()
            async def pbs(ctx: commands.Context):
                db_user = await bot.lookup_or_register_user(ctx.author)
                embed = await bot.build_player_card_embed(db_user, ctx.author)
                await ctx.send(embed=embed)

            @bot.command()
            async def categories(ctx: commands.Context):
                categories = await bot.data.get_run_categories()
                response_str = 'Allowed categories are:\n'
                for category in categories:
                    response_str += '{name}\n'.format(**category)
                await ctx.send(response_str)

            await bot.start(os.environ['GGB_DISCORD_TOKEN'])

asyncio.run(main())