# github-pull-requests

# Installation

 - install [Hammerspoon](http://www.hammerspoon.org/) - a powerfull automation tool for OS X
   - Manually:

      Download the [latest release](https://github.com/Hammerspoon/hammerspoon/releases/latest), and drag Hammerspoon.app from your Downloads folder to Applications.
   - Homebrew:

      ```brew install hammerspoon --cask```

 - download [github-pull-requests.spoon](https://github.com/fork-my-spoons/github-pull-requests.spoon/releases/latest/download/github-pull-requests.spoon.zip), unzip and double click on a .spoon file. It will be installed under `~/.hammerspoon/Spoons` folder.
 
 - install `gh` - [GitHub CLI](https://cli.github.com/)

 - open ~/.hammerspoon/init.lua and add the following snippet, with your repositories:

```lua
-- github pull requests
hs.loadSpoon("github-pull-requests")
spoon['github-pull-requests']:setup({
  repos = {'streetturtle/awesome-wm-widgets',
    'Hammerspoon/hammerspoon',
    'cli/cli'
  }
})
spoon['github-pull-requests']:start()
```


This app uses icons, to properly display them, install a [feather-font](https://github.com/AT-UI/feather-font) by [downloading](https://github.com/AT-UI/feather-font/raw/master/src/fonts/feather.ttf) this .ttf font and installing it.