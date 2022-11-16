local wibox = require("wibox")
local gears = require("gears")
local awful = require("awful")
local theme = require("beautiful")
local naughty = require("naughty")
local glib = require("lgi").GLib
local dpi = theme.xresources.apply_dpi

local module = {}

local client, screen, mouse, awesome = client, screen, mouse, awesome

local glib_context = function(fn)
	return function(args)
		glib.idle_add(glib.PRIORITY_DEFAULT_IDLE, function()
			fn(args)
		end)
	end
end

local function doubleclicked(obj)
	if obj.doubleclick_timer then
		obj.doubleclick_timer:stop()
		obj.doubleclick_timer = nil
		return true
	end
	obj.doubleclick_timer = gears.timer.start_new(0.3, function()
		obj.doubleclick_timer = nil
	end)
	return false
end

local add_hot_corner = function(args)
	args = args or {}
	local position = args.position or ""
	local placement = awful.placement[position]
	if not placement then
		return
	end
	local actions = args.buttons or {}
	local s = args.screen or awful.screen.focused()
	local width = args.width
	local height = args.height
	local color = args.color

	local corner = awful.popup({
		screen = s,
		placement = placement,
		ontop = true,
		border_width = 0,
		minimum_height = height,
		maximum_height = height,
		minimum_width = width,
		maximum_width = width,
		bg = color,
		widget = wibox.container.background,
	})

	-- this will run for every screen, so we have to make sure to only add one signal handler for every assigned signal
	local must_connect_signal = (s.index == 1)

	local function signal_name(pos, action)
		return "hot_corners::" .. pos .. "::" .. action
	end

	local defs = {
		{ name = "left_click", button = 1 },
		{ name = "middle_click", button = 2 },
		{ name = "right_click", button = 3 },
		{ name = "wheel_up", button = 4 },
		{ name = "wheel_down", button = 5 },
		{ name = "back_click", button = 8 },
		{ name = "forward_click", button = 9 },
	}

	local buttons = {}
	for _, btn in ipairs(defs) do
		if actions[btn.name] then
			local signal = signal_name(position, btn.name)
			table.insert(
				buttons,
				awful.button({}, btn.button, function()
					awesome.emit_signal(signal)
				end)
			)
			if must_connect_signal then
				awesome.connect_signal(signal, glib_context(actions[btn.name]))
			end
		end
	end
	corner:buttons(buttons)

	for _, action in pairs({ "enter", "leave" }) do
		if actions[action] then
			local signal = signal_name(position, action)
			corner:connect_signal("mouse::" .. action, function()
				awesome.emit_signal(signal)
			end)
			if must_connect_signal then
				awesome.connect_signal(signal, glib_context(actions[action]))
			end
		end
	end
end

local function new(config)
	local cfg = config or {}

	local hot_corners = cfg.hot_corners or {}
	local hot_corners_color = cfg.hot_corners_color or "#00000000"
	local hot_corners_width = cfg.hot_corners_width or dpi(1)
	local hot_corners_height = cfg.hot_corners_height or dpi(1)

	local button_funcs = {}

	local left_click_function = function(c)
		if doubleclicked(c) then
			button_double_click(c)
		else
			button_left_click(c)
		end
	end

	client.connect_signal("smart_borders::left_click", left_click_function)
	--client.connect_signal("smart_borders::middle_click", button_middle_click)
	--client.connect_signal("smart_borders::right_click", button_right_click)
	--client.connect_signal("smart_borders::wheel_up", button_wheel_up)
	--client.connect_signal("smart_borders::wheel_down", button_wheel_down)
	--client.connect_signal("smart_borders::back_click", button_back)
	--client.connect_signal("smart_borders::forward_click", button_forward)

	button_funcs[1] = function(c)
		c:emit_signal("smart_borders::left_click")
	end

	button_funcs[2] = function(c)
		c:emit_signal("smart_borders::middle_click")
	end
	button_funcs[3] = function(c)
		c:emit_signal("smart_borders::right_click")
	end
	button_funcs[4] = function(c)
		c:emit_signal("smart_borders::wheel_up")
	end
	button_funcs[5] = function(c)
		c:emit_signal("smart_borders::wheel_down")
	end
	button_funcs[8] = function(c)
		c:emit_signal("smart_borders::back_click")
	end
	button_funcs[9] = function(c)
		c:emit_signal("smart_borders::forward_click")
	end
	--local function handle_button_press(c, button)
	--	local func = button_funcs[button]
	--	if func then
	--		func(c)
	--	end
	--end

	for s in screen do
		for pos, btns in pairs(hot_corners) do
			add_hot_corner({
				buttons = btns,
				screen = s,
				position = pos,
				color = hot_corners_color,
				width = hot_corners_width,
				height = hot_corners_height,
			})
		end
	end
end

return setmetatable(module, {
	__call = function(_, ...)
		new(...)
		return module
	end,
})
