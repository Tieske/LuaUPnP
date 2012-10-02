--[[
Original file from LuaDoc, included 2-Oct-2012
merged from 'lp.lua' and 'html.lua'

Copyright © 2004-2007 The Kepler Project.

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE
]]

---------------------------------------------------------------------
-- Lua Pages template engine. Code was taken from LuaDoc and adapted
-- for LuaUPnP.
-- @class module
-- @name upnp.lp
-- @copyright 2004-2007 The Kepler Project, LuaUPnP modifications 2012 <a href="http://www.thijsschreijer.nl">Thijs Schreijer</a>, <a href="http://github.com/Tieske/LuaUPnP">LuaUPnP</a>
-- @release Version 0.x, LuaUPnP.


local find, format, gsub, strsub = string.find, string.format, string.gsub, string.sub

local lp = {}

----------------------------------------------------------------------------
-- function to do output
local outfunc = "return"

--
-- Builds a piece of Lua code which outputs the (part of the) given string.
-- @param s String.
-- @param i Number with the initial position in the string.
-- @param f Number with the final position in the string (default == -1).
-- @return String with the correspondent Lua code which outputs the part of the string.
--
local function out (s, i, f)
	s = strsub(s, i, f or -1)
	if s == "" then return s end
	-- we could use `%q' here, but this way we have better control
	s = gsub(s, "([\\\n\'])", "\\%1")
	-- substitute '\r' by '\'+'r' and let `loadstring' reconstruct it
	s = gsub(s, "\r", "\\r")
	return format(" %s('%s'); ", outfunc, s)
end


----------------------------------------------------------------------------
-- Translate the template to Lua code.
-- @param s String to translate.
-- @return String with translated, but not compiled, code.
----------------------------------------------------------------------------
function lp.translate (s)
	s = gsub(s, "<%%(.-)%%>", "<?lua %1 ?>")
	local res = {}
	local start = 1   -- start of untranslated part in `s'
	while true do
		local ip, fp, target, exp, code = find(s, "<%?(%w*)[ \t]*(=?)(.-)%?>", start)
		if not ip then break end
		table.insert(res, out(s, start, ip-1))
		if target ~= "" and target ~= "lua" then
			-- not for Lua; pass whole instruction to the output
			table.insert(res, out(s, ip, fp))
		else
			if exp == "=" then   -- expression?
				table.insert(res, format(" %s(%s);", outfunc, code))
			else  -- command
				table.insert(res, format(" %s ", code))
			end
		end
		start = fp + 1
	end
	table.insert(res, out(s, start))
	return table.concat(res)
end


----------------------------------------------------------------------------
-- Defines the name of the output function.
-- @param f String with the name of the function which produces output. Default
-- value is <code>"return"</code>.

function lp.setoutfunc (f)
	outfunc = f
end

-- Looks for a file `name' in given path. Removed from compat-5.1
-- @param path String with the path.
-- @param name String with the name to look for.
-- @return String with the complete path of the file found
--	or nil in case the file is not found.
local function search (path, name)
  for c in string.gfind(path, "[^;]+") do
    c = gsub(c, "%?", name)
    local f = io.open(c)
    if f then   -- file exist?
      f:close()
      return c
    end
  end
  return nil    -- file not found
end

----------------------------------------------------------------------------
-- Internal compilation cache.

local cache = {}

----------------------------------------------------------------------------
-- Translates a template into a compiled Lua function.
-- Does NOT execute the resulting function.
-- @param str String with the template to be translated.
-- @param chunkname String with the name of the chunk, for debugging purposes.
-- @return Function with the resulting translation.

function lp.compile (str, chunkname)
	local f, err = loadstring (lp.translate (str), chunkname)
	if not f then error (err, 3) end
	return f
end

----------------------------------------------------------------------------
-- Translates and executes a template in a given file.
-- The translation creates a Lua function which will be executed in an
-- optionally given environment.
-- @param filename String with the name of the file containing the template.
-- Once compiled the template function will be cached, based on the filename.
-- @param env Table with the environment to run the resulting function.
-- If <code>nil</code> then a new environment will be used, both the new and
-- the provided environment will be equipped with the basic Lua functions.
-- @return the results of the function set by <code>lp.setoutfunc()</code>, but might also
-- throw an error

function lp.includefile (filename, env)
  local prog = cache[filename]
  if not prog then
    -- read the whole contents of the file
    local fh = assert (io.open (filename))
    local src = fh:read("*a")
    fh:close()
    -- translates the file into a function
    prog = lp.compile (src, '@'..filename)
    cache[filename] = prog
  end

	env = env or {}
	env.table = table
	env.io = io
	env.lp = M
  env.pairs = pairs
	env.ipairs = ipairs
	env.tonumber = tonumber
	env.tostring = tostring
	env.type = type
	setfenv (prog, env)

	return prog ()
end

----------------------------------------------------------------------------
-- Translates and executes a template in a given 'module'. It will search 
-- for a file located in the module path. It will look for a <code>'.upnp'</code> extension
-- The translation creates a Lua function which will be executed in an
-- optionally given environment (will call the <code>lp.includefile()</code> function).
-- @param template String with the name of the module containing the template.
-- @param env Table with the environment to run the resulting function.
-- @return the results of the function set by <code>lp.setoutfunc()</code>, but might also
-- throw an error

function lp.includemodule(template, env)
	-- search using package.path (modified to search .lp instead of .lua
	local search_path = string.gsub(package.path, "%.lua", "%.upnp")
	local templatepath = search(search_path, template)
	assert(templatepath, string.format("template `%s' not found", template))

	return lp.includefile(templatepath, env)
end

----------------------------------------------------------------------------
-- Translates and executes a template in a given 'module' or file. This method
-- enables to call directly on the module table. It will first call 
-- <code>lp.includefile()</code>, and if that fails <code>lp.includemodule()</code>
-- @name __call
-- @class function
-- @param name the file or module name.
-- @param env Table with the environment to run the resulting function.
-- @return the results or <code>nil + errormsg</code>
setmetatable(lp, { __call = function(self, name, env)
    local success, result = pcall(lp.includefile, name, env)
    if not success then
      success, result = self.includemodule(lp.includemodule, name, env)
    end
    if success then return result end
    return nil, result  -- it's an error
  end})

return lp
