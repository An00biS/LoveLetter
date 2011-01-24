-------------------------------------------------------------------------------
-- LoveLetter project
-- Handlers for several tags
-------------------------------------------------------------------------------

local luadoc = require "luadoc"
local util = require "luadoc.util"
local string = require "string"
local table = require "table"
local assert, type, tostring = assert, type, tostring
local print = print;

module "luadoc.taglet.LoveLetter.tags"

-------------------------------------------------------------------------------

local function author (tag, block, text)
	block[tag] = block[tag] or {}
	if not text then
		luadoc.logger:warn("author `name' not defined [["..text.."]]: skipping")
		return
	end
	table.insert (block[tag], text)
end

-------------------------------------------------------------------------------
-- Set the class of a comment block. Classes can be "module", "function",
-- "table". The first two classes are automatic, extracted from the source code

local function class (tag, block, text)
	block[tag] = text
end

-------------------------------------------------------------------------------

local function copyright (tag, block, text)
	block[tag] = text
end

-------------------------------------------------------------------------------

local function description (tag, block, text)
	block[tag] = text
end

-------------------------------------------------------------------------------

local function field (tag, block, text, loveLetter)
	if block["class"] ~= "table" then
		luadoc.logger:warn("documenting `field' for block that is not a `table'")
	end
	block[tag] = block[tag] or {}

	local _, _, name, desc = string.find(text, "^([_%w%.]+)%s+(.*)")
	local errMsg = "";
	if loveLetter.debug then
		errMsg = errMsg .. string.format("\t\ntag:%s\t\nblock (table#%d) :%s\t\ntext:%s\nname:%s\ndesc:%s", tostring(tag), #block, table.concat(block), tostring(text), tostring(name), tostring(desc));
	end
	if not text or text == "" then
		loveLetter:error("Field name not defined"..errMsg)
	elseif not name and not desc then
		name, desc = text, "";
	else

	end

	table.insert(block[tag], name)
	block[tag][name] = desc
	--print(string.format("DBG tags.field() ------------------------------- \t\ntag:%s\t\nblock (table#%d) :%s\t\ntext:%s\nname:%s\ndesc:%s\n", tostring(tag), #block, table.concat(block), tostring(text), tostring(name), tostring(desc)));
end

-------------------------------------------------------------------------------
-- Set the name of the comment block. If the block already has a name, issue
-- an error and do not change the previous value

local function name (tag, block, text)
	if block[tag] and block[tag] ~= text then
		luadoc.logger:error(string.format("block name conflict: `%s' -> `%s'", block[tag], text))
	end

	block[tag] = text
end

-------------------------------------------------------------------------------
-- Processes a parameter documentation.
-- @param tag String with the name of the tag (it must be "param" always).
-- @param block Table with previous information about the block.
-- @param text String with the current line beeing processed.

local function param (tag, block, text)
	block[tag] = block[tag] or {}
	-- TODO: make this pattern more flexible, accepting empty descriptions
	local _, _, name, desc = string.find(text, "^([_%w%.]+)%s+(.*)")
	if not name then
		luadoc.logger:warn("parameter `name' not defined [["..text.."]]: skipping")
		return
	end
	local i = table.foreachi(block[tag], function (i, v)
		if v == name then
			return i
		end
	end)
	if i == nil then
		luadoc.logger:warn(string.format("documenting undefined parameter `%s'", name))
		table.insert(block[tag], name)
	end
	block[tag][name] = desc
end

-------------------------------------------------------------------------------

local function release (tag, block, text)
	block[tag] = text
end

-------------------------------------------------------------------------------

local function ret (tag, block, text)
	tag = "ret"
	if type(block[tag]) == "string" then
		block[tag] = { block[tag], text }
	elseif type(block[tag]) == "table" then
		table.insert(block[tag], text)
	else
		block[tag] = text
	end
end

-------------------------------------------------------------------------------
-- @see ret

local function see (tag, block, text)
	-- see is always an array
	block[tag] = block[tag] or {}

	-- remove trailing "."
	text = string.gsub(text, "(.*)%.$", "%1")

	local s = util.split("%s*,%s*", text)

	table.foreachi(s, function (_, v)
		table.insert(block[tag], v)
	end)
end

-------------------------------------------------------------------------------
-- @see ret

local function usage (tag, block, text)
	if type(block[tag]) == "string" then
		block[tag] = { block[tag], text }
	elseif type(block[tag]) == "table" then
		table.insert(block[tag], text)
	else
		block[tag] = text
	end
end

-------------------------------------------------------------------------------

local handlers = {}
handlers["author"] = author
handlers["class"] = class
handlers["copyright"] = copyright
handlers["description"] = description
handlers["field"] = field
handlers["name"] = name
handlers["param"] = param
handlers["release"] = release
handlers["return"] = ret
handlers["see"] = see
handlers["usage"] = usage

-------------------------------------------------------------------------------

function handle (tag, block, text, loveLetter)
	if not handlers[tag] then
		luadoc.logger:error(string.format("undefined handler for tag `%s'", tag))
		return
	end
--	assert(handlers[tag], string.format("undefined handler for tag `%s'", tag))
	return handlers[tag](tag, block, text, loveLetter);
end
