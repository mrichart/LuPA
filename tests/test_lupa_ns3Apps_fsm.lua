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

--auxiliar functions
local lineal_func = function(a,b,x)
  return a*x+b
end

local round = function(num)
  return math.floor(num + 0.5)
end

local getDomain = function(universe)
  if universe == "rate" or universe == "power" then
    return {-3,-2,-1,0,1,2,3}
  end
end

--functions
functions.fAnd = function(f1,f2,l)
  local ret1 = f1(l)
  local ret2 = f2(l)
  local maxVal = -100
  if ret1 < ret2 then
    return ret1
  else
    return ret2
  end
end

functions.event_hl = function(loss)
  if loss < 0.3 then
    return lineal_func((0.2/0.3),0,loss)
  else
    return lineal_func((0.2/0.7),0.5/0.7,loss)
  end
end

functions.event_ll = function(loss)
  if loss < 0.3 then
    return lineal_func(-(0.2/0.3),1,loss)
  else
    return lineal_func(-(0.2/0.7),0.2/0.7,loss)
  end
end

functions.event_hp = function(pow)
  if pow < 10 then
    return lineal_func((0.5/10),0,pow)
  else
    return lineal_func((0.2/7),3.6/7,pow)
  end
end

functions.event_mp = function(pow)
  if pow < 5 then
    return lineal_func((0.5/5),0,pow)
  elseif pow < 8 then
    return lineal_func((0.2/3),0,pow)
  else
    return lineal_func((0.2/7),3.6/7,pow)
  end
end

events.event_lp(e)
	if e.mib and e.value and string.match(e.mib, "sProb", 1) then
	  lineal_func(tonumber(e.value) > 0.5 then
	  return 1
	else
	  return 0
	end
end


--notifications


--begin generated code
--------------------------------------------------------------------------
--initialization
local initialization_notifs = {
}
local initialization_subs = {
}
--predicates


--actions

actions.action1 = function()
  local levels = getDomain('rate')
  local maxRet = -100  
  for _,l in ipairs(levels) do
    ret = fAnd(f1,f2,l)
    if ret > maxRet then
      maxRet = ret
    end
  end
  return maxRet
end

local func_action_kr = function(l)
  return round(lineal_func(-1/3,1,l))
end

local notif_action_kr = function(l,e)
	return {
    {target_host="127.0.0.1", target_service="NS3-PEP", notification_id=math.random(2^30), 
	  command="change_rate", level=l, station=e.station},
	}
end

action_action_kr = function(e)
  local domain, levels = getDomain("func_action_kr")
  local maxVal = -1
  local bestLevel
  for _,l in ipairs(levels) do
    local ret = func_action_kr(l)
    if ret > maxVal then
      bestLevel = l
    end
  end
  return notif_action_kr(bestLevel,e)
end

local func_action_ir = function(l)
  return round(lineal_func(1/6,0.5,l))
end

local notif_action_ir = function(l,e)
	return {
    {target_host="127.0.0.1", target_service="NS3-PEP", notification_id=math.random(2^30), 
	  command="increase_rate", level=l, station=e.station},
	}
end

action_action_ir = function(e)
  local domain, levels = getDomain("func_action_ir")
  local maxVal = -1
  local bestLevel
  for _,l in ipairs(levels) do
    local ret = func_action_ir(l)
    if ret > maxVal then
      bestLevel = l
    end
  end
  return notif_action_ir(bestLevel,e)
end

local func_action_dr = function(l)
  return round(lineal_func(-1/6,0.5,l))
end

local notif_action_dr = function(l,e)
	return {
    {target_host="127.0.0.1", target_service="NS3-PEP", notification_id=math.random(2^30), 
	  command="decrease_rate", level=l, station=e.station},
	}
end

action_action_dr = function(e)
  local domain, levels = getDomain("func_action_dr")
  local maxVal = -1
  local bestLevel
  for _,l in ipairs(levels) do
    local ret = func_action_dr(l)
    if ret > maxVal then
      bestLevel = l
    end
  end
  return notif_action_dr(bestLevel,e)
end

--transition
--{state, predicate, new state, action} 
local fsm = FSM{
	{"ini",	is_ev_prob_high,		"end", 	{action_action_ir}	 	},
	{"ini",	is_ev_prob_low, 	"end", 	{action_action_dr} 	},
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
