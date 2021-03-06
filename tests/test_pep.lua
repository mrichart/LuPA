require("socket")

local name=arg[1] or "test_pep"
local host=arg[2] or "localhost"
local port=arg[3] or 8182

local function randomize ()
	local fl = io.open("/dev/urandom");
	local res = 0;
	for f = 1, 4 do res = res*256+(fl:read(1)):byte(1, 1); end;
	fl:close();
	math.randomseed(res);
end;
randomize()

local subsnid = name .. "_sub" .. tostring(math.random(2^30)) 
local subsn = "SUBSCRIBE\nhost=".. name .."\nsubscription_id=" ..subsnid
	.. "\nttl=20\nFILTER\ntarget_host=" .. name .."\nEND\n"
--local hello = "HELLO\nsubscriptor_id="..name.."\nEND\n"

local function unescape (s)
	s = string.gsub(s, "+", " ")
  	s = string.gsub(s, "%%(%x%x)", function (h)
		return string.char(tonumber(h, 16))
	  	end)
  	return s
end
local function escape (s)
  	s = string.gsub(s, "([&=+%c])", function (c)
		return string.format("%%%02X", string.byte(c))
  		end)
  	s = string.gsub(s, " ", "+")
  	return s
end

local action_print ="NOTIFICATION\n"
.."notification_id=cmndid" .. tostring(math.random(2^30))  .."\n"
.."message_type=action\n"
.."host=" ..name.. "\n"
.."timestamp=" ..os.time().. "\n"
.."target_host=the_node\n"
.."target_service=/lupa/pep\n"
.."command=print\n"
.."message=OPI!\n"
.."END\n"
local action_os_execute ="NOTIFICATION\n"
.."notification_id=cmndid" .. tostring(math.random(2^30))  .."\n"
.."message_type=action\n"
.."host=" ..name.. "\n"
.."timestamp=" ..os.time().. "\n"
.."target_host=the_node\n"
.."target_service=/lupa/pep\n"
.."command=os_execute\n"
.."shell_command=uname -a\n"
.."END\n"


print("Starting", name, host, port)
print("Connecting...")
local client = assert(socket.connect(host, port))
print("Connected.")
if os.execute("/bin/sleep 1") ~= 0 then return end	

client:send(subsn)
print("Subscribed.")
if os.execute("/bin/sleep 1") ~= 0 then return end	

client:send(action_print)
print("action_print sent.")
client:send(action_os_execute)
print("action_os_execute sent.")

--if os.execute("/bin/sleep 1") ~= 0 then return end	
print("===Reading===")
repeat
	local line, err = client:receive()
	if line then 
		print("-", unescape(line) ) 
	end
until err
client:close()
