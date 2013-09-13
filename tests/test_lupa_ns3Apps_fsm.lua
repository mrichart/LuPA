print ("FSM loading...")

local function FSM(t)
	local a = {}
	for _,v in ipairs(t) do
		local old, t_function, new, actions = v[1], v[2], v[3], v[4]
    
    if a[old] == nil then a[old] = {} end
    if new then
      table.insert(a[old],{new = new, actions = actions, t_function = t_function})
    end    
  end
  return a
end


--auxiliar functions to be used when detecting happening events
local function register_as_happening(event)
  happening_events[event]=true
end
local function unregister_as_happening(event)
  happening_events[event]=nil
end
local function unregister_as_happening_f(filter)
	for event, _ in pairs(happening_events) do
		local matches = true
		for key, value in pairs(filter) do
			if not event[key]==value then
				matches=false
				break
			end
		end
		if matches then
			happening_events[event]=nil
		end
	end	
end


local shared = {}

--begin generated code
--------------------------------------------------------------------------
--initialization
local initialization_notifs = {
}
local initialization_subs = {
}
--predicates
local function is_ev_prob_high(e)
	if e.mib and e.value and string.match(e.mib, "sProb", 1) and tonumber(e.value) > 0.5 then
	  return 1
	else
	  return 0
	end
end
local function is_ev_prob_low(e)
	if e.mib and e.value and string.match(e.mib, "sProb", 1) and tonumber(e.value) <= 0.5 then
	  return 1
	else
	  return 0
	end
end

local function is_ev_rate(e)
	if e.mib and e.value and string.match(e.mib, "rate", 1) then
	  return 1
	else
	  return 0
	end
end

local function is_ev_power(e)
	if e.mib and e.value and string.match(e.mib, "power", 1) then
	  return 1
	else
	  return 0
	end
end

--actions
local function action_decrease_rate(e)
	print ("DECREASE RATE!") 
	return {
		{target_host="127.0.0.1", target_service="NS3-PEP", notification_id=math.random(2^30), 
		command="decrease_rate", level="1", station=e.station},
	}
end
local function action_increase_rate(e)
	print ("INCREASE RATE!") 
	return {
		{target_host="127.0.0.1", target_service="NS3-PEP", notification_id=math.random(2^30), 
		command="increase_rate", level="1", station=e.station},
	}
end

--transition
--{state, predicate, new state, action} 
local fsm = FSM{
	{"ini",	is_ev_prob_high,		"end", 	{action_increase_rate}	 	},
	{"ini",	is_ev_prob_low, 	"end", 	{action_decrease_rate} 	},
		{"ini",	is_ev_rate,		"end", nil	},
				{"ini",	is_ev_power,		"end", nil	},
				{"end",	nil,	nil, nil	},
}

local init_state = "ini"

--final states
local is_accept =   {
['end']=true,
}

--------------------------------------------------------------------------
--end generated code

local current_state=init_state --current state
local i_event=1 --current event in window

function initialize()
 	print("FSM: initializing")
	return initialization_subs or {}, initialization_notifs or {}
end

local function dump_window()
	local s="=> "
	for _,e in ipairs(window) do
		if e.event.message_type=="trap" then
			s=s .. tostring(e.event.mib) ..","
		else
			s=s .. "#,"
		end
	end
	return s
end

--advances the machine a single step.
--returns nil if arrives at the end the window, or the event is not recognized
--otherwise, returns the resulting list from the action
local function fst_step()
	local event_reg = window[i_event]
	if not event_reg then return end --window finished
	local event=event_reg.event
			
	local state=fsm[current_state]
  assert(#state>0)
	--search first transition that verifies e
	local best_tf=-1
	local transition
	for _, l in ipairs(state) do
    local tf=l.t_function(event)
    if best_tf<tf then
      best_tf=tf
      transition=l
    end
	end 
  assert(transition)
	
	local ret_call = {}
	if transition.actions then
    for _, action in ipairs(transition.actions) do
      local ret_action = action(event)
      for _, v in ipairs(ret_action) do ret_call[#ret_call+1] = v end
    end
  end
  
	i_event=i_event+1
	current_state = transition.new
	print (current_state, #fsm[current_state],  #ret_call, is_accept[current_state], #fsm[current_state]==0)
  return ret_call, is_accept[current_state], #fsm[current_state]==0
end

function step()
	print("FSM: WINDOW STEP ", #window, dump_window())
	
	local ret, accept, final = {}, false, false
  
  repeat
    local ret_step
		ret_step, accept, final = fst_step()
		if ret_step then 
			for _, r in ipairs(ret_step) do ret[#ret+1]=r	end --queue generated actions
		end
  until accept or i_event==#window
  assert(not (final and not accept))
  
  if accept then
    --purge consumed events from window
    print("Purge consumed events", #window)
    local i=1
    local e = window[i_event]
    repeat
      if happening_events[window[i]] then
        i=i+1
      else
        table.remove(window, i)
        i_event=i_event-1
      end
    until window[i]==e
    if not happening_events[window[i]] then table.remove(window, i) end
    print("Purge consumed events", #window)
  end
  
	if #ret>0 then
		print ("FSM: WINDOW STEP generating output ", #ret, accept, final, current_state)
	end
	return ret, accept, final
end

function reset()
  current_state=init_state 
  i_event=1 
  happening_events={}
  print ("FSM: RESET")
end

print ("FSM loaded.")
