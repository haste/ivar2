-- ivar2 IRC module
-- vim: set noexpandtab:
local util = require'util'
local utf8 = util.utf8

local function parse(line)
    local source, command, destination, argument
    if(line:sub(1, 1) ~= ':') then
        command, argument = line:match'^(%S+) :(.*)'
        if(command) then
            return command, argument, 'server'
        end
    elseif(line:sub(1, 1) == ':') then
        if(not source) then
            -- Parse 352 /who
            local tsource, tcommand, sourcenick, tdestination, user, host, server, nick, mode, hopcount, realname = line:match('^:(%S+) (%d%d%d) (%S+) (%S+) (%S+) (%S+) (%S+) (%S+) (%S+) (%S+) (.-)$')
            if(tsource and tcommand == '352') then
                local argument = {}
                argument.mode = mode
                argument.user = user
                argument.server = server
                argument.nick = nick
                argument.sourcenick = sourcenick
                argument.hopcount = hopcount
                argument.realname = realname
                argument.host = host
                -- Return here. This command does not need further
                -- parsing or checking for ignore.
                return tcommand, argument, tsource, tdestination
            end
        end
        if(not source) then
            -- :<server> 000 <nick> <destination> :<argument>
            source, command, destination, argument = line:match('^:(%S+) (%d%d%d) %S+ ([^%d]+[^:]+) :(.*)')
        end
        if(not source) then
            -- :<server> 000 <nick> <int> :<argument>
            source, command, argument = line:match('^:(%S+) (%d%d%d) [^:]+ (%d+ :.+)')
            if(source) then argument = argument:gsub(':', '', 1) end
        end
        if(not source) then
            -- :<server> 000 <nick> <argument> :<argument>
            source, command, argument = line:match('^:(%S+) (%d%d%d) %S+ (.+) :.+$')
        end
        if(not source) then
            -- :<server> 000 <nick> :<argument>
            source, command, argument = line:match('^:(%S+) (%d%d%d) [^:]+ :(.*)')
        end
        if(not source) then
            -- :<server> 000 <nick> <argument>
            source, command, argument = line:match('^:(%S+) (%d%d%d) %S+ (.*)')
        end
        if(not source) then
            -- :<server> <command> <destination> :<argument>
            source, command, destination, argument = line:match('^:(%S+) (%u+) ([^:]+) :(.*)')
        end
        if(not source) then
            -- :<source> <command> <destination> <argument>
            source, command, destination, argument = line:match('^:(%S+) (%u+) (%S+) (.*)')
        end
        if(not source) then
            -- :<source> <command> :<destination>
            source, command, destination = line:match('^:(%S+) (%u+) :(.*)')
        end
        if(not source) then
            -- :<source> <command> <destination>
            source, command, destination = line:match('^:(%S+) (%u+) (.*)')
        end
        return command, argument, source, destination
    end
end

local split = function(hostmask, destination, message, trail)
	if not message then return end
	local msgtype = 'privmsg'
	if not trail then
		trail = ' (…)'
	end
	local extra
	if not hostmask then hostmask = 'xxxxxxxxxxxxxxxxxxx' end
	local cutoff = 512 - 6 - #hostmask - #destination - #msgtype - #trail
	if #message > cutoff then
		local len = 0
		extra = {}
		local out = {}
		-- Iterate over valid utf8 string so we don't cut off in the middle
		-- of a utf8 codepoint
		for c in utf8.chars(message) do
			if len <= cutoff then
				-- Check if the length of the current char
				-- fits inside the remaining space
				local remainder = cutoff - len
				if #c < remainder then
					table.insert(out, c)
				else
					table.insert(extra, c)
				end
				len = len + #c
			else
				table.insert(extra, c)
			end
		end
		out = table.concat(out)
		extra = table.concat(extra)
		message = out .. trail
	end
	return message, extra
end

local formatCtcp = function(message, type)
	return string.format('\001%s %s\001', type, message)
end

return {
	parse=parse,
	split=split,
	formatCtcp=formatCtcp,
}
