local folder = ".tracker/";
local repo = "https://raw.githubusercontent.com/BeastWalnut/CC-PlayerTracker/master/";
local function wget(file)
	shell.run("wget", repo .. file, folder .. file)
end

wget("api.lua");
wget("app.lua");
wget("utils.lua");
