============================
ivar2 - DO-OH!
============================

Introduction
------------
ivar2 is an irc-bot on speed, with a mentally unstable mind.
Partially because its written in lua, which could make the most sane mind go unstable.

Installation
------------------

Install required dependencies

::

    sudo apt-get install luarocks libev-dev liblua5.1-iconv0 lua-cjson cmake libsqlite3-dev
    sudo luarocks install "https://github.com/brimworks/lua-ev/raw/master/rockspec/lua-ev-scm-1.rockspec"
    sudo luarocks install "https://github.com/Neopallium/nixio/raw/master/nixio-scm-0.rockspec"
    sudo luarocks install "https://github.com/Neopallium/lua-handlers/raw/master/lua-handler-scm-0.rockspec"
    sudo luarocks install "https://github.com/brimworks/lua-http-parser/raw/master/lua-http-parser-scm-0.rockspec"
    sudo luarocks install "https://github.com/Neopallium/lua-handlers/raw/master/lua-handler-http-scm-0.rockspec"
    sudo luarocks install lsqlite3
    sudo luarocks install luasocket
    sudo luarocks install luabitop


Uncompress the required data files in cache directory.

Configuration File
------------------

Create a bot config sort of like this

**myconfig.lua**

::

    return {
        nick = 'ivar2',
        autoReconnect = true,
        ident = 'ivar2',
        uri = 'tcp://irc.efnet.no:6667/?laddr=my.host.name&lport=0',
        realname = 'ivar',
        owners = {
            'nick!ident@my.host.name'
        },
        webserverhost = '*',
        webserverport = 9000,
        webserverprefix = 'https://my.web.proxy/', -- optional URL if bot is behind proxy
        commandPattern = "!",
        notice = false, -- Reply with PRIVMSG instead of NOTICE
        modules = {
            'admin',
            'autojoin',
            'lastfm',
            'spotify',
            'karma',
            'roll',
            'title',
            'tvrage',
            'urbandict',
            'substitute',
            'lua',
        },
        channels = {
            ['#ivar'] = {
                disabledModules = {
                    'olds'
               },
               commandPattern = '>',
               ignoredNicks = {'otherbot'},
               modulePatterns = {
                    lastfm = '#',
               },
            },
        }
    }



Launch bot
----------

::

    lua ivar2.lua myconfig.lua

Modules
-------

THERES TONS!
