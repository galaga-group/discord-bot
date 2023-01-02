from dataclasses import dataclass
from datetime import date, datetime
import asyncio
import asyncpg

@dataclass
class galaga_group_bot_data():
    pool: asyncpg.pool.Pool

    @classmethod
    async def create(cls, host: str, database: str, user: str, password: str):
        pool = await asyncpg.create_pool(user=user, password=password, database=database, host=host)
        self = galaga_group_bot_data(pool)
        return self
    
    async def get_run_categories(self):
        async with self.pool.acquire() as conn:
            return await conn.fetch('SELECT * FROM run_category')

    async def lookup_user(self, did: int):
        async with self.pool.acquire() as conn:
            return await conn.fetchrow('SELECT * FROM lookup_user($1)', did)

    async def register_user(self, did: int, name: str, display_name: str, discriminator: int):
        async with self.pool.acquire() as conn:
            return await conn.fetchrow('SELECT * FROM register_user($1, $2, $3, $4)', did, name, display_name, discriminator)

#    async def lookup_category(self, category: str):
#        async with self.pool.acquire() as conn:
#            return await conn.fetchrow('SELECT * FROM lookup_category($1)', category)

    async def do_submission(self, user_id: int, category: str, score: int, evidence_link: str):
        async with self.pool.acquire() as conn:
            try:
                await conn.execute('SELECT do_submission($1, $2, $3, $4)', user_id, category, score, evidence_link)
            except Exception as e:
                print(e)
    
    async def get_personal_best_scores(self, user_id: int):
        async with self.pool.acquire() as conn:
            return await conn.fetch('SELECT * FROM get_player_best_scores($1)', user_id)

    async def __aenter__(self):
        return self

    async def __aexit__(self, *excinfo):
        await self.pool.close()

    