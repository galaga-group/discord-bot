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
    
    def __del__(self):
        asyncio.run(self.pool.close())

    