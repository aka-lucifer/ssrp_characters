Thread = {}
ThreadMethods = {}

ThreadMethods.__call = function(self, fnc, looped, ms)
	if type(fnc) ~= "function" then assert(nil, "Function parameter expected function, but got " .. type(fnc)) return end
	if type(looped) ~= "boolean" then assert(nil, "Loop parameter expected boolean, but got " .. type(looped)) return end
  if type(ms) ~= "number" then assert(nil, "MS parameter expected number, but got " .. type(ms)) return end
	
	local o = setmetatable({}, {
		__index = self,
		__type = 'Thread',
	})

	o.state = "running"
	o.delay = ms

	Citizen.CreateThread(function()
        if looped then
            while true do

                if o.state == "running" then
                    fnc(nil)
                end

                if o.state == "dead" then
                    return
                end

                Citizen.Wait(o.delay)
            end
        else
            local p = promise.new()
            fnc(p)
            Citizen.Await(p)
            o:Kill()
        end
    end)
	return o
end

ThreadMethods.__index = {
	Pause = function(self)
		if self.state == "dead" then return end
		self.state = "paused"
	end,

	Resume = function(self)
		if self.state == "dead" then return end
		self.state = "running"
	end,
	
	Kill = function(self)
		if self.state == "dead" then return end
		self.state = "dead"
	end,
	
	Status = function(self)
		return self.state
	end,

	GetDelay = function(self)
		return self.delay
	end,
	
	ChangeDelay = function(self, ms)
		if type(ms) ~= "number" then assert(nil, "MS parameter expected number, but got " .. type(ms)) return end
		self.delay = ms
	end
}

setmetatable(Thread, ThreadMethods)