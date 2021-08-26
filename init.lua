local obj = {}
obj.__index = obj

-- Metadata
obj.name = "GitHub Pull Requests"
obj.version = "1.0"
obj.author = "Pavel Makhov"
obj.homepage = "https://github.com/fork-my-spoons/github-pull-requests.spoon"
obj.license = "MIT - https://opensource.org/licenses/MIT"

obj.indicator = nil
obj.iconPath = hs.spoons.resourcePath("icons")
obj.menu = {}
obj.task = nil

local calendar_icon = hs.styledtext.new(' ', { font = {name = 'feather', size = 12 }, color = {hex = '#8e8e8e'}})
local user_icon = hs.styledtext.new(' ', { font = {name = 'feather', size = 12 }, color = {hex = '#8e8e8e'}})
local draft_icon = hs.styledtext.new(' ', { font = {name = 'feather', size = 12 }, color = {hex = '#ffd60a'}})


local function show_warning(text)
    hs.notify.new(function() end, {
        autoWithdraw = false,
        title = 'GitHub Contributions Spoon',
        informativeText = string.format(text)
    }):send()
end

--- Converts string representation of date (2020-06-02T11:25:27Z) to date
local function parse_date(date_str)
    local pattern = "(%d+)%-(%d+)%-(%d+)T(%d+):(%d+):(%d+)%Z"
    local y, m, d, h, min, sec, _ = date_str:match(pattern)

    return os.time{year = y, month = m, day = d, hour = h, min = min, sec = sec}
end

--- Converts seconds to "time ago" represenation, like '1 hour ago'
local function to_time_ago(seconds)
    local days = seconds / 86400
    if days > 1 then
        days = math.floor(days + 0.5)
        return days .. (days == 1 and ' day' or ' days') .. ' ago'
    end

    local hours = (seconds % 86400) / 3600
    if hours > 1 then
        hours = math.floor(hours + 0.5)
        return hours .. (hours == 1 and ' hour' or ' hours') .. ' ago'
    end

    local minutes = ((seconds % 86400) % 3600) / 60
    if minutes > 1 then
        minutes = math.floor(minutes + 0.5)
        return minutes .. (minutes == 1 and ' minute' or ' minutes') .. ' ago'
    end
end

local function subtitle(text)
    return hs.styledtext.new(text, {color = {hex = '#8e8e8e'}})
end

local function split(s, delimiter)
    result = {};
    for match in (s..delimiter):gmatch("(.-)"..delimiter) do
        table.insert(result, match);
    end
    return result;
end

function obj:update_indicator(exitCode, stdout, stderr)
    self.menu = {}

    if (stderr ~= '') then 
        show_warning(stderr) 
        print(stderr)
        return
    end

    for folder in hs.fs.dir(os.getenv("HOME") .. "/.cache/github-pull-requests/") do
        if folder ~= '.' and folder ~= '..' then 
            
            for file in hs.fs.dir(os.getenv("HOME") .. "/.cache/github-pull-requests/" .. folder) do
                if file ~= '.' and file ~= '..' then 
                    
                    local current_time = os.time(os.date("!*t"))
                    
                    local pulls = hs.json.read(os.getenv("HOME") .. "/.cache/github-pull-requests/" .. folder .. '/' .. file)
                    
                    table.sort(pulls, function(left, right) return left.createdAt > right.createdAt end)
                    local submenu = {}
                    for k, pull in pairs(pulls) do
                        local pull_title = hs.styledtext.new(pull.title .. '\n')
                        .. calendar_icon .. subtitle(to_time_ago(os.difftime(current_time, parse_date(pull.createdAt))) .. '   ')
                        .. user_icon .. subtitle(pull.author.login)

                        if pull.isDraft == true then
                            pull_title = draft_icon .. pull_title
                        end

                        table.insert(submenu, {
                            title = pull_title,
                            image = hs.image.imageFromURL('http://github.com/' .. pull.author.login .. '.png?size=36'):setSize({w=36,h=36}),
                            fn = function() os.execute('open ' .. pull.url) end
                        })
                    end

                    table.insert(self.menu, {
                        title = file,
                        image = hs.image.imageFromURL('http://github.com/' .. folder .. '.png?size=36'):setSize({w=36,h=36}),
                        menu = submenu
                    })

                end
            end
        end
    end

    self.indicator:setMenu(self.menu)
end

function obj:init()
    self.indicator = hs.menubar.new()
end

function obj:init()
    self.indicator = hs.menubar.new()
    self.indicator:setIcon(hs.image.imageFromPath(self.iconPath .. '/git-pull-request.png'):setSize({w=16,h=16}), true)

end

function obj:setup(args)
    self.repos = args.repos
end

function obj:start()

    local task_params = {hs.spoons.resourcePath("get_pr.sh")}

    for _, v in pairs(self.repos) do
        table.insert(task_params, v)
    end

    hs.timer.new(600, function()

    self.task = hs.task.new('/bin/bash',
        function(exitCode, stdout, stderr) self:update_indicator(exitCode, stdout, stderr) end,
        task_params):start()        
    end):start():fire()

end

return obj