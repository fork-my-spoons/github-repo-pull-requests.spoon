local obj = {}
obj.__index = obj

-- Metadata
obj.name = "GitHub Repo Pull Requests"
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
local branch_icon = hs.styledtext.new(' ', { font = {name = 'feather', size = 12 }, color = {hex = '#8e8e8e'}})
local comment_icon = hs.styledtext.new(' ', { font = {name = 'feather', size = 12 }, color = {hex = '#8e8e8e'}})
local draft_icon = hs.styledtext.new(' ', { font = {name = 'feather', size = 12 }, color = {hex = '#ffd60a'}})


local function show_warning(text)
    hs.notify.new(function() end, {
        autoWithdraw = false,
        title = obj.name,
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

local function create_menu_item_title(pull, current_time)
    return hs.styledtext.new(pull.title .. '\n')
        .. calendar_icon .. subtitle(to_time_ago(os.difftime(current_time, parse_date(pull.createdAt))))
        .. hs.styledtext.new('   +' .. pull.additions, {color = {hex = '#A3BE8C'}}) .. hs.styledtext.new('   -' .. pull.deletions .. '   ', {color = {hex = '#BF616A'}}) 
        .. user_icon .. subtitle(pull.author.login .. '\n')
        .. branch_icon .. subtitle(pull.headRefName .. ' -> ' .. pull.baseRefName)
end


function obj:check_for_updates()
    local release_url = 'https://api.github.com/repos/fork-my-spoons/github-repo-pull-requests.spoon/releases/latest'
    hs.http.asyncGet(release_url, {}, function(status, body)
        local latest_release = hs.json.decode(body)
        latest = latest_release.tag_name:sub(2)
        
        if latest == self.version then
            hs.notify.new(function() end, {
                autoWithdraw = false,
                title = self.name,
                informativeText = "You have the latest version installed!"
            }):send()
        else
            hs.notify.new(function() 
                os.execute('open ' .. latest_release.assets[1].browser_download_url)
            end, 
            {
                title = self.name,
                informativeText = "New version is available",
                actionButtonTitle = "Download",
                hasActionButton = true
            }):send()
        end
    end)
end


function obj:update_indicator(exitCode, stdout, stderr)
    self.menu = {}

    if (stderr ~= '') then 
        show_warning(stderr) 
        print(stderr)
        return
    end
    
    local current_time = os.time(os.date("!*t"))
    
    for folder in hs.fs.dir(os.getenv("HOME") .. "/.cache/github-pull-requests/") do
        if folder ~= '.' and folder ~= '..' then 
            
            for file in hs.fs.dir(os.getenv("HOME") .. "/.cache/github-pull-requests/" .. folder) do
                if file ~= '.' and file ~= '..' then 
                    
                    local pulls = hs.json.read(os.getenv("HOME") .. "/.cache/github-pull-requests/" .. folder .. '/' .. file)
                    
                    local my_pulls = {}
                    local all_pulls = {}
                    local draft_pulls = {}

                    for k, pull in pairs(pulls) do
                        if pull.isDraft then
                            table.insert(draft_pulls, pull)
                        else        
                            pull.toReview = false
                            for k, req in pairs(pull.reviewRequests) do
                                if req.login == 'streetturtle' then
                                    pull.toReview = true
                                end
                            end
                            if pull.toReview then 
                                table.insert(my_pulls, pull)
                            else 
                                table.insert(all_pulls, pull)
                            end
                        end
                    end

                    if self.hide_drafts == true then draft_pulls = {} end
                            
                    table.sort(my_pulls, function(left, right) return left.createdAt > right.createdAt end)
                    table.sort(all_pulls, function(left, right) return left.createdAt > right.createdAt end)
                    table.sort(draft_pulls, function(left, right) return left.createdAt > right.createdAt end)
                    
                    local submenu = {}
                    local header = false

                    if #my_pulls > 0 then
                        table.insert(submenu, { title = '-'})
                        table.insert(submenu, { title = 'PRs to review', disabled = true})
                        for k, pull in pairs(my_pulls) do

                            table.insert(submenu, {
                                title = create_menu_item_title(pull, current_time),
                                image = hs.image.imageFromURL('http://github.com/' .. pull.author.login .. '.png?size=36'):setSize({w=36,h=36}),
                                fn = function() os.execute('open ' .. pull.url) end
                            })
                        end
                    end

                    table.insert(submenu, {title = '-'})
                    table.insert(submenu, {title = 'All PRs', disabled = true})
                    for k, pull in pairs(all_pulls) do
                        table.insert(submenu, {
                            title = create_menu_item_title(pull, current_time),
                            image = hs.image.imageFromURL('http://github.com/' .. pull.author.login .. '.png?size=36'):setSize({w=36,h=36}),
                            fn = function() os.execute('open ' .. pull.url) end
                        })
                    end

                    if #draft_pulls > 0 then
                        table.insert(submenu, { title = '-'})
                        table.insert(submenu, { title = 'Drafts', disabled = true})
                        for k, pull in pairs(draft_pulls) do

                            local pull_title = hs.styledtext.new(pull.title .. '\n')
                            .. calendar_icon .. subtitle(to_time_ago(os.difftime(current_time, parse_date(pull.createdAt))) .. '   ')
                            .. user_icon .. subtitle(pull.author.login)

                            table.insert(submenu, {
                                title = create_menu_item_title(pull, current_time),
                                image = hs.image.imageFromURL('http://github.com/' .. pull.author.login .. '.png?size=36'):setSize({w=36,h=36}),
                                fn = function() os.execute('open ' .. pull.url) end
                            })
                        end
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

    table.insert(self.menu, {title = '-'})

    table.insert(self.menu, { 
        image = hs.image.imageFromName('NSRefreshTemplate'), 
        title = 'Refresh', fn = function() self:refresh() end
    })

    table.insert(self.menu, { 
        image = hs.image.imageFromName('NSTouchBarDownloadTemplate'), 
        title = 'Check for updates', 
        fn = function() self:check_for_updates() end
    })
    
    self.indicator:setMenu(self.menu)
end

function obj:refresh() 
    hs.task.new('/bin/bash', function(exitCode, stdout, stderr) 
        self:update_indicator(exitCode, stdout, stderr) 
    end,
    self.task_params)
        :start()
end

function obj:init()
    self.indicator = hs.menubar.new()
    self.indicator:setIcon(hs.image.imageFromPath(self.iconPath .. '/git-pull-request.png'):setSize({w=16,h=16}), true)
end

function obj:setup(args)
    self.repos = args.repos
    self.hide_drafts = args.hide_drafts or false
end

function obj:start()

    self.task_params = {
        hs.spoons.resourcePath("get_pull_requests.sh")
    }
    
    for _, v in pairs(self.repos) do
        table.insert(self.task_params, v)
    end

    self.timer = hs.timer.new(600, function() self:refresh() end)
    self.timer:start():fire()

end

return obj