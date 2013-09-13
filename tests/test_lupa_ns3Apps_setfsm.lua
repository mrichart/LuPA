require("socket")

io.stdout:setvbuf("line")

local name=arg[1] or "test_lupa"
local host=arg[2] or "127.0.0.1"
local port=arg[3] or 8182

local subsnid = name .. "_sub" .. tostring(math.random(2^30)) 
local subsn = "SUBSCRIBE\nhost=".. name .."\nsubscription_id=" ..subsnid
	.. "\nttl=20\nFILTER\ntarget_host=" .. name .."\nEND\n"

local function unescape (s)
	s = string.gsub(s, "+", " ")
  	s = string.gsub(s, "%%(%x%x)", function (h)
		return string.char(tonumber(h, 16))
	  	end)
  	return s
end

print("Starting", name, host, port)
print("Connecting...")
local client = assert(socket.connect(host, port))
print("Connected.")
socket.sleep(1)

client:send(subsn)
print("Subscribed.")
socket.sleep(1)

local action ="NOTIFICATION\n"
.."notification_id=cmndid#RANDOM#\n"
.."message_type=action\n"
.."host=" ..name.. "\n"
.."timestamp=" ..os.time().. "\n"
.."target_service=#NAME_PDP#\n"
.."command=set_fsm_file\n"
.."fsm_name=lupa/tests/test_lupa_ns3Apps_fsm.lua\n"
.."END\n"

local i, action_copy, proper_name
proper_name = "AP0/lupa/pdp"
print(proper_name)

action_copy = string.gsub(action, "#NAME_PDP#", proper_name)
action_copy = string.gsub(action_copy, "#RANDOM#", tostring(math.random(2^30)))
client:send(action_copy)
socket.sleep(1)
print("Action  sent.")

print("===Reading===")
repeat
	local line, err = client:receive()
	if line then 
		print("-", unescape(line) ) 
	end
until err
client:close()
