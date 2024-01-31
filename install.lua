local folder = ".tracker/";
local function wget(link, file)
	shell.run("wget", link, folder .. file)
end

wget(
	"https://raw.githubusercontent.com/BeastWalnut/CC-PlayerTracker/main/api.lua?token=GHSAT0AAAAAACLYTNB5AI5JKSX7FZ3YDU7AZNZWUXA",
	"api.lua"
);
wget(
	"https://raw.githubusercontent.com/BeastWalnut/CC-PlayerTracker/main/app.lua?token=GHSAT0AAAAAACLYTNB5TFHHVYQHEJOG3D54ZNZWWNA",
	"app.lua"
);
wget(
	"https://raw.githubusercontent.com/BeastWalnut/CC-PlayerTracker/main/utils.lua?token=GHSAT0AAAAAACLYTNB52WW4IKVR7TQXJEO6ZNZWXHQ",
	"utils.lua"
);
