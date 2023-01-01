FROM python:3.10-alpine3.17

# Working directory (all scripts are copied here)
WORKDIR /srv/gg

# Copy over python module requirements
COPY requirements.txt ./

# Install the required modules
RUN python -m pip install -r ./requirements.txt

# Copy over the scripts for the bot.
COPY galaga_group_bot.py ./
#COPY galaga_group_bot_data.py ./

CMD [ "python", "./galaga_group_bot.py" ]