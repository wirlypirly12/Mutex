--[[

 __  __            _                     
|  \/  |  _  _    | |_     ___    __ __  
| |\/| | | +| |   |  _|   / -_)   \ \ /  
|_|__|_|  \_,_|   _\__|   \___|   /_\_\  
_|"""""|_|"""""|_|"""""|_|"""""|_|"""""| 
"`-0-0-'"`-0-0-'"`-0-0-'"`-0-0-'"`-0-0-' 

A coroutine safe mutex for Roblox with deadlock detection and FIFO queuing.

Github (repository)
https://github.com/wirlypirly12/Mutex

--------------------------------------------------------------------------------
MIT License

Copyright (c) 2026 wirlypirly12

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
--------------------------------------------------------------------------------

--]]

local mutex = {}
mutex.__index = mutex

function mutex.new()
	return setmetatable({
		locked = false,
		head = nil,
		tail = nil,
	}, mutex)
end

function mutex:lock()
	if not coroutine.isyieldable() then
		error("This thread is not yieldable! Consider using tryLock instead")
	end

	local thread = coroutine.running()

	if self.owner == thread then
		error("This coroutine already owns this mutex")
	end

	local node = {
		thread = thread,
		next = nil,
	}

	if self.locked then
		if self.tail then
			self.tail.next = node
		else
			self.head = node
		end
		self.tail = node
		coroutine.yield()
	else
		self.owner = thread
		self.locked = true
	end
end

function mutex:tryLock()
	if self.locked then
		return false
	else
		self.owner = coroutine.running()
		self.locked = true
		return true
	end
end

function mutex:unlock()
	local thread = coroutine.running()

	if not self.locked then
		error("Mutex is not locked")
	end
	if self.owner ~= thread then
		error("This isn't your mutex")
	end

	if self.head then
		local next_node = self.head
		self.head = next_node.next
		if not self.head then
			self.tail = nil
		end

		while next_node and coroutine.status(next_node.thread) == "dead" do
			next_node = self.head
			if next_node then
				self.head = next_node.next
				if not self.head then
					self.tail = nil
				end
			end
		end

		if next_node then
			self.owner = next_node.thread
			task.defer(coroutine.resume, next_node.thread)
		else
			self.owner = nil
			self.locked = false
		end
	else
		self.owner = nil
		self.locked = false
	end
end

function mutex:run(callback, ...)
	self:lock()
	local ok, res = pcall(callback, ...)
	self:unlock()
	if not ok then
		error(res, 0)
	end
	return res
end

return mutex.new
