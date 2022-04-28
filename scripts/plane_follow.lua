-- main settings
local LOOP_UPDATE_RATE_HZ = 20 -- main loop update interval

-- global variable declarations
local target_pos = Location()
local current_pos = Location()
local target_velocity = Vector3f()
local target_heading = 0.0
local have_target = false

-- bind a parameter to a variable
function bind_param(name)
    local p = Parameter()
    assert(p:init(name), string.format("could not find %s parameter", name))
    return p
end

-- add a parameter and bind it to a variable
function bind_add_param(name, idx, default_value)
    assert(param:add_param(PARAM_TABLE_KEY, idx, name, default_value), string.format("could not add param %s", name))
    return bind_param(PARAM_TABLE_PREFIX .. name)
end

-- check key parameters
function check_parameters()

    -- parameters to check
    local key_params = {
        FOLL_ENABLE = 1,
        FOLL_OFS_TYPE = 1,
        FOLL_ALT_TYPE = 0,
    }

    -- check and set parameters
    for p, v in pairs(key_params) do
        local current = param:get(p)
        assert(current, string.format("parameter %s not found", p))
        if math.abs(v - current) > 0.001 then
            param:set_and_save(p, v)
            gcs:send_text(0, string.format("parameter %s set to %.2f was %.2f", p, v, current))
        end
    end
end

-- update target state
function update_target()
   if not follow:have_target() then
      if have_target then
         gcs:send_text(0,"lost leader")
      end
      have_target = false
      return
   end
   if not have_target then
      gcs:send_text(0,"found leader")
   end
   have_target = true

   target_pos, target_velocity = follow:get_target_location_and_velocity_ofs()
   target_heading = follow:get_target_heading_deg()
end

-- main function that will be called within loop
function update()
    update_target() -- update target data
end

-- loop function to call main update function
function loop()
    update()
    return loop, 1000 // LOOP_UPDATE_RATE_HZ
end

-- protected loop function to call main update function
function protected_wrapper()
    local success, err = pcall(update)
    if not success then
        gcs:send_text(0, "Internal Error: " .. err)
        return protected_wrapper, 1000
    end
    return protected_wrapper, 1000 // LOOP_UPDATE_RATE_HZ
end

-- check parameters before starting the main loop
check_parameters()

-- initial call for protected loop function
return protected_wrapper()
