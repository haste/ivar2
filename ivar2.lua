local connection = require'handler.connection'
local ev = require'ev'
local loop = ev.Loop.default

local events = {
	['PING'] = {
		{
			'core',
			function(self, time)
				self:Send(string.format('PONG %s', time))
			end,
		},
	},
	['433'] = {
		{
			'core',
			function(self)
				local nick = self.config.nick:sub(1,8) .. '_'
				self:Nick(nick)
			end,
		},
	},
}

local safeCall = function(self, moduleName, func, ...)
	local success, message = pcall(func, self, ...)

	if(not success) then
		return
	end

	return message
end

local safeFormat = function(format, ...)
	if(select('#', ...) > 0) then
		local success, message = pcall(string.format, format, ...)
		if(success) then
			return message
		end
	else
		return format
	end
end

local tableHasValue = function(table, value)
	if(type(table) ~= 'table') then return end

	for _, v in next, table do
		if(v == value) then return true end
	end
end

local client = {
	ignores = {},
	Loop = loop,

	Send = function(self, format, ...)
		local message = safeFormat(format, ...)
		print(message)
		if(message) then
			message = message:gsub('[\r\n]+', '')

			self.socket:send(message .. '\r\n')
		end
	end,

	Quit = function(self, message)
		self.config.autoReconnect = nil

		if(message) then
			return self:Send('QUIT :%s', message)
		else
			return self:Send'QUIT'
		end
	end,

	Join = function(self, channel)
		return self:Send('JOIN %s', channel)
	end,

	Part = function(self, channel)
		return self:Send('PART %s', channel)
	end,

	Topic = function(self, destination, topic)
		if(topic) then
			return self:Send('TOPIC %s :%s', destination, topic)
		else
			return self:Send('TOPIC %s', destination)
		end
	end,

	Mode = function(self, destination, mode)
		return self:Send('MODE %s %s', destination, mode)
	end,

	Kick = function(self, destination, user, comment)
		if(comment) then
			return self:Send('KICK %s %s :%s', destination, user, comment)
		else
			return self:Send('KICK %s %s', destination, user)
		end
	end,

	Notice = function(self, destination, format, ...)
		return self:Send('NOTICE %s :%s', destination, format, ...)
	end,

	Privmsg = function(self, destination, format, ...)
		return self:Send('PRIVMSG %s :%s', destination, format, ...)
	end,

	Msg = function(self, type, destination, source, ...)
		local handler = type == 'notice' and 'Notice' or 'Privmsg'
		if(destination == self.config.nick) then
			-- Send the respons as a PM.
				return self[handler](self, source.nick or source, ...)
		else
			-- Send it to the channel.
			return self[handler](self, destination, ...)
		end
	end,

	Nick = function(self, nick)
		self.config.nick = nick
		return self:Send('NICK %s', nick)
	end,

	ParseMaskNick = function(self, source)
		return source:match'([^!]+)!'
	end,

	ParseMask = function(self, mask)
		local source = {}
		source.mask, source.nick, source.ident, source.host = mask, mask:match'([^!]+)!([^@]+)@(.*)'
		return source
	end,

	DispatchCommand = function(self, command, argument, source, destination)
		if(not events[command]) then return end

		if(source) then source = self:ParseMask(source) end

		for _, module in next, events[command] do
			local moduleName, callback, pattern = module[1], module[2], module[3]

			if(not self:IsModuleDisabled(moduleName, destination)) then
				if(pattern and argument:match(pattern)) then
					safeCall(self, moduleName, callback, source, destination, argument:match(pattern))
				elseif(not pattern) then
					safeCall(self, moduleName, callback, argument)
				end
			end
		end
	end,

	IsModuleDisabled = function(self, moduleName, destination)
		local channel = self.config.channels[destination]

		if(type(channel) == 'table') then
			return tableHasValue(channel.disabledModules, moduleName)
		end
	end,

	Ignore = function(mask)
		self.ignores[mask] = true
	end,

	Unignore = function(mask)
		self.ignores[mask] = nil
	end,

	IsIgnored = function(self, destination, source)
		if(self.ignores[source]) then return true end

		local channel = self.config.channels[destination]
		local nick = self:ParseMaskNick(source)
		if(type(channel) == 'table') then
			return tableHasValue(channel.ignoredNicks, nick)
		end
	end,

	EnableModule = function(self, moduleName, moduleTable)
		for command, handlers in next, moduleTable do
			if(not events[command]) then events[command] = {} end

			for pattern, handler in next, handlers do
				if(type(pattern) ~= 'string') then pattern = nil end

				table.insert(
					events[command],
					{
						moduleName,
						handler,
						pattern,
					}
				)
			end
		end
	end,

	DisableModule = function(self, moduleName)
		for command, handlers in next, events do
			for key, handler in next, handlers do
				if(handlers[1] == moduleName) then
					table.remove(handlers, key)
				end
			end
		end
	end,

	DisableAllModules = function(self)
		for command, handlers in next, events do
			for key, handler in next, handlers do
				if(handler[1] ~= 'core') then
					table.remove(handlers, key)
				end
			end
		end
	end,

	LoadModules = function(self)
		if(self.config.modules) then
			for _, moduleName in next, self.config.modules do
				local moduleTable = safeCall(self, moduleName, assert(loadfile('modules/' .. moduleName .. '.lua'))())
				if(moduleTable) then
					self:EnableModule(moduleName, moduleTable)
				end
			end
		end
	end,

	Log = function(self, level, format, ...)
		local message = safeFormat(format, ...)
		print(level, format)
	end,

	Connect = function(self, config)
		self.config = config

		local bindHost, bindPort
		if(config.bind) then
			bindHost, bindPort = unpack(config.bind)
		end

		self.socket = connection.tcp(loop, self, config.host, config.port, bindHost, bindPort)

		self:DisableAllModules()
		self:LoadModules()
	end,

	handle_error = function(self, err)
		if(self.config.autoReconnect) then
			ev.Timer.new(
				function(loop, timer, revents)
					self.socket:close()
					self:Connect(self.config)
				end,
				60
			):start(loop)
		else
			loop:stop(loop)
		end
	end,

	handle_connected = function(self)
		self:Send(string.format('NICK %s\r\n', self.config.nick))
		self:Send(string.format('USER %s %s blah :%s\r\n', self.config.ident, self.config.host, self.config.realname))
	end,

	handle_data = function(self, data)
		if(self.overflow) then
			data = self.overflow .. data
			self.overflow = nil
		end

		for line in data:gmatch('[^\n]+') do
			if(line:sub(-1) ~= '\r') then
				self.overflow = line
			elseif(line:sub(1,1) ~= ':') then
				self:DispatchCommand(line:match('([^:]+) :(.*)'))
			elseif(line:sub(1,1) == ':') then
				local source, command, destination, argument
				if(line:match' :') then
					source, command, destination, argument = line:match('(%S+) ([%u%d]+) ([^:]+) :(.*)')
				else
					source, command, destination, argument = line:match('(%S+) ([%u%d]+) (%S+) (.*)')
				end

				if(not self:IsIgnored(destination, source)) then
					self:DispatchCommand(command, argument, source, destination)
				end
			end

			if(not self.overflow) then
				print(line)
			end
		end
	end,
}

return client