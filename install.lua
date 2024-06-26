---@param repo string
---@param folder string
local function github_get(repo, folder)
	local url = "https://api.github.com/repos/" .. repo .. "/contents"
	local ok, err = http.checkURL(url)
	if not ok then
		print(err)
		return
	end

	local response = http.get(url)
	if not response then
		print("Failed to get file names")
		return
	end

	---@class GitResponse
	---@field name string
	---@field download_url string

	---@type GitResponse[] | nil
	local files = textutils.unserialiseJSON(response.readAll() or "")
	response.close()
	if not files then
		print("Error finding repository: " .. repo)
		return
	end

	for _, file_data in ipairs(files) do
		local file_response = http.get(file_data.download_url)
		local path = folder .. file_data.name
		if file_response then
			local file = fs.open(path, "w")
			if file then
				file.write(file_response.readAll() or "")
				file.close()
				print("Succesfully installed: " .. path)
			else
				print("Could not edit file: " .. path)
			end
			file_response.close()
		else
			print("Could not install: " .. file_data.name)
		end
	end
end

term.clear()
term.setCursorPos(1, 1)
github_get("BeastWalnut/CC-PlayerTracker", ".tracker/")
