--[[
Copyright (C) 2024 Michael Slíva <michael@sliva.dev>
Licensed under the Academic Free License version 3.0

You should have received a copy of the Academic Free License version 3.0 
along with this program. If not, see <https://spdx.org/licenses/AFL-3.0.html>.
]]--

-- Settings
local app_name = 'discord-canary' -- or 'discord'
local package_manager = 'urpmi' -- or 'dnf'

-- Consts
local SUPPORTED_APPS = {['discord'] = true, ['discord-canary'] = true}
local SUPPORTED_PACKAGE_MANAGERS = {['urpmi'] = true, ['dnf'] = true}

-- Vars
local temp_path = os.getenv('HOME')
local update_url = 'https://discord.com/api/download'..(string.find(app_name, 'canary') and '/canary' or '')..'?platform=linux&format=deb'
local update_state_str = 'splashScreen.updateSplashState'
local update_state_type
local new_version
local target_download_file_name
local generated_rpm_file_name
local pid


function string:startswith(start)
  return self:sub(1, #start) == start
end


local function get_keys(table)
  local result = ''
  for k, v in pairs(table) do 
    result = result .. (result == '' and '' or ', ') .. k
  end
  return result
end


local function download_update()
  print('Starting download of an update file as '..target_download_file_name..' from source address '..update_url)
  local pipe = assert(io.popen('wget -O "'..temp_path..target_download_file_name..'" "'..update_url..'"'))
  pipe:flush()
  pipe:close()
end


local function convert_deb_to_rpm()
  print('Converting .deb package to .rpm')
  local pipe = assert(io.popen('pkexec --keep-cwd alien -r --scripts "'..temp_path..target_download_file_name..'"'))
  repeat 
    local c = pipe:read('L')
    if c then
      if not generated_rpm_file_name then generated_rpm_file_name = c:match('[^%s]+') end
      pipe:flush()
    end
  until not c
  pipe:close()
end


local function install_update()
  print('Installing update with package manager')
  local pipe = assert(io.popen('pkexec '..package_manager..' '..(string.find(package_manager, 'dnf') and 'install ' or '')..'"'..temp_path..generated_rpm_file_name..'"'))
  pipe:flush()
  pipe:close() 
end


local function get_current_pid()
  return io.open('/proc/self/stat', 'rb'):read():match('[^%s]+')
end


function os.capture(cmd)
  local pipe = io.popen(cmd, 'r')
  repeat
    local c = pipe:read('L')
    if c then
      if c:startswith(update_state_str) then
        update_state_type = c:match(update_state_str..'%s([^%s]+)')
        if update_state_type == 'update-manually' then
          print('Update found! Starting update process...')
          new_version = c:match('newVersion:%s\'([^\']+)')
          print('New version is '..new_version)
          print('Killing all child processes of PID '..pid)
          os.execute('pkill -P '..pid)
          target_download_file_name = app_name..'-'..new_version..'.deb'
          download_update()
          print('Download complete')
          convert_deb_to_rpm()
          print('Conversion complete')
          install_update()
          print('Installation complete')
          print('Cleanup')
          os.execute('rm "'..temp_path..target_download_file_name..'" "'..temp_path..generated_rpm_file_name..'"')
          --os.execute('pkexec rm -rf "'..temp_path..app_name..'-'..new_version..'/"') -- deleted automatically after Alien finishes
        elseif update_state_type then do --[[continue]] end
        else
          print('No manual update required :) Restarting in normal mode...')
          os.execute('pkill -P '..pid)
        end
      end
      --io.write(c) --> DEBUG
      pipe:flush()
    end
  until not c
  pipe:close()
end


-- Main
if not SUPPORTED_APPS[app_name] then error('"'..app_name..' is not supported app! Supported options are "'..get_keys(SUPPORTED_APPS)..'"') end
if not SUPPORTED_PACKAGE_MANAGERS[package_manager] then error('"'..package_manager..'" is not supported package manager! Supported options are "'..get_keys(SUPPORTED_PACKAGE_MANAGERS)..'"') end

pid = get_current_pid()
if temp_path:sub(-1) ~= '/' then temp_path = temp_path..'/' end
os.capture(app_name)
os.execute(app_name..'&')

print('Done!')
