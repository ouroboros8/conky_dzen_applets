-- applets.lua
--
-- Some lua applets for use in conky config files, designed to be used in
-- conjunction with dzen.
-- 
-- functions in this file are essentially lua applets for conky, and can be
-- called in conky using the lua api (with lua_parse). These functions should
-- take as input a table-formatted string of keyword arguments (of the form
-- {keyword=value, keyword_two=value_two, ...}).
--
-- conky_colorised_battery(), for instance, outputs battery status and charge
-- percentage, padded to a fixed width, and colorised depending on battery
-- charge.
-- 
-- applets will use a number of worker functions, located in 'workers.lua'. For
-- example, conky_colorised_batmon() calls the worker function colorise() on the
-- battery value, then pads the battery string it produces using pad(). Both of
-- these functions return a table which keeps formatting and values seperated;
-- it is up to the applet to combine them.

require 'workers'
require 'helpers'

function conky_battery(args)

  args = get_args(args)

  local low = tonumber(args.low) or 20
  local lcol = args.lowcolor or '#FF0000'
  local hcol = args.highcolor or '#0000FF'
  local ccol = args.chargecolor or '#00FF00'
  -- 1 status indicator icon + 1 space + 3 digits
  -- = 5 chars
  local width = args.width or 5
  local ac_icon = args.ac_icon or "/home/dan/.xmonad/dzen2/ac_01.xbm"
  local no_ac_icon = args.no_ac_icon or "/home/dan/.xmonad/dzen2/arr_down.xbm"
  local ac_icon_col = args.ac_icon_color or nil
  local no_ac_icon_col = args.no_ac_icon_color or nil

  -- Check battery status
  local status, value = unpack(split(tostring(conky_parse("${battery_short}")), ' '))

  -- Deal with the less usual statuses.
  if status == 'F' then
    status = 'C'
    value = "100%"
  elseif status == 'E' then
    status = 'D'
    value = "0%"
  elseif status == 'U' then
    local leftpad, rightpad = fixed_width_pad('???', width, 'c')
    return leftpad .. '???' .. rightpad
  elseif status == 'N' then
    return dzen_fg('#FF0000').."Battery not present"..dzen_fg()
  elseif status ~= 'C' and status ~= 'D' then
    error("conky_colorised_barrery: something went wrong processing battery status\n"
          .."Expected 'D', 'C', 'F' or 'U', but got '"..status.."'")
  end

  local val_err = "Error processng value "..value.." into number."
  value = assert(value:match("(%d?%d?%d)%%"), val_err)

  local icon, icon_col = nil -- This is just for variable scope purposes
  if status == 'C' then
    status_name = 'charging'
    icon = ac_icon
    icon_col = ac_icon_col
  else
    status_name = 'discharging'
    icon = no_ac_icon
    icon_col = no_ac_icon_col
  end
  icon = dzen_ico(icon)
  icon_col = dzen_fg(icon_col)

  -- Now get the formatting for the number color.
  local valcol_l, valcol_r = nil
  if status == 'D' then
    valcol_l, valcol_r = dynamic_colorise(value, low, lcol, hcol)
      if not valcol_l then
        valcol_l, valcol_r = '', ''
      end
  else
    valcol_l, valcol_r = dzen_fg(ccol), dzen_fg()
  end

  -- Get padding
  local value_width = string.len(value) + 2 -- Plus two characters for the icon and the space
  local lpad, rpad = fixed_width_pad(value_width, width)

  return icon_col..icon..lpad..' '..valcol_l..value..valcol_r..'%'..rpad
end

function conky_cpu(args)

  args = get_args(args)

  local low = tonumber(args.low) or 15
  local high = tonumber(args.high) or 70
  local lcol = args.lowcolor or '#00FF00'
  local mcol = args.mediumcolor or '#FFFF00'
  local hcol = args.highcolor or '#FF0000'
  local width = args.width or 3

  local value = conky_parse("${cpu}")
  local val_err = "Problem processing cpu output"..value..": could not convert to number."
  value = assert(tonumber(value), val_err)

  local valcol_l, valcol_r = dynamic_colorise(value, low, lcol) -- if above low, return nil
  if not valcol_l then
    valcol_l, valcol_r = dynamic_colorise(value, high, mcol, hcol)
    if not valcol_l then
      valcol_l, valcol_r = '', ''
    end
  end

  local value_width = string.len(value) -- Plus two characters for the icon and the space
  local lpad, rpad = fixed_width_pad(value_width, width)

  return lpad..valcol_l..value..valcol_r..rpad
end
