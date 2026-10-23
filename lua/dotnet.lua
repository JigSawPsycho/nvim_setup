-- Builds and debugs .NET projects with the dotnet CLI and netcoredbg.
-- The debugger runs the built DLL directly instead of using `dotnet run`, so nothing reads
-- launchSettings.json for us. This module reads it and passes the chosen profile's
-- environment variables, URLs and arguments to the app, the way `dotnet run` would.
--
-- Lua needs a local function defined before it's used, so the helpers come first and the
-- two entry points (build_solution_or_project and debug_project) are at the bottom.
--
-- Helpers that run dotnet or read files throw on failure. Each keymap and picker callback
-- catches with pcall and shows the message, so a new step that runs from a callback needs
-- its own pcall too, or the user gets a raw Lua error.
local M = {}

-- Turns MSBuild lines like `/src/Foo.cs(10,5): error CS1002: ; expected [/src/App.csproj]`
-- into quickfix entries. Errors from MSBUILD or CSC have no file, so they're kept as plain
-- text. Other output is dropped.
local BUILD_ERROR_FORMAT = table.concat({
    "%f(%l\\,%c): %trror %m",
    "%f(%l\\,%c): %tarning %m",
    "%f(%l): %trror %m",
    "%f(%l): %tarning %m",
    "%+GMSBUILD : %.%#",
    "%+GCSC : %.%#",
    -- Project-level problems such as NuGet errors, reported against the .csproj.
    "%f : %trror %m",
    "%f : %tarning %m",
    "%-G%.%#",
}, ",")

-- Two builds at once fight over the same obj/ folder, so only one runs at a time.
local is_build_running = false

local function notify_error(message)
    vim.notify(message, vim.log.levels.ERROR)
end

local function current_buffer_dir()
    if vim.bo.buftype ~= "" or vim.api.nvim_buf_get_name(0) == "" then
        return vim.fn.getcwd()
    end
    return vim.fs.dirname(vim.api.nvim_buf_get_name(0))
end

local function find_solution(start_dir)
    return vim.fs.find(function(name)
        return name:match("%.slnx?$") ~= nil
    end, { upward = true, path = start_dir, type = "file" })[1]
end

local function find_nearest_project(start_dir)
    return vim.fs.find(function(name)
        return name:match("%.csproj$") ~= nil
    end, { upward = true, path = start_dir, type = "file" })[1]
end

-- Every dotnet command runs next to the file it works on, because dotnet picks its SDK
-- from the global.json above the working directory.
local function run_dotnet(arguments, file)
    local command = vim.list_extend({ "dotnet" }, arguments)
    local result = vim.system(command, { text = true, cwd = vim.fs.dirname(file) }):wait()
    if result.code ~= 0 then
        error(table.concat(command, " ") .. " failed:\n" .. result.stdout .. result.stderr, 0)
    end
    return result.stdout
end

local function list_solution_projects(solution)
    local solution_dir = vim.fs.dirname(solution)
    return vim.iter(vim.split(run_dotnet({ "sln", solution, "list" }, solution), "\n"))
        :map(vim.trim)
        :filter(function(line) return line:match("%.csproj$") ~= nil end)
        -- The extra parentheses keep only gsub's string, not its count of replacements.
        :map(function(line) return vim.fs.joinpath(solution_dir, (line:gsub("\\", "/"))) end)
        :totable()
end

-- Class libraries can't be launched on their own, so they aren't offered. Test projects that
-- set OutputType to Exe (xUnit v3 does) are offered too. This reads the .csproj text only, so
-- an OutputType set in Directory.Build.props is missed, and a commented-out one still counts.
local function is_runnable(project)
    if vim.fn.filereadable(project) == 0 then return false end

    local text = table.concat(vim.fn.readfile(project), "\n"):lower()
    -- The quote or slash after the name stops this matching Microsoft.NET.Sdk.WebAssembly,
    -- which netcoredbg can't run. The slash is for SDKs with a version, like Sdk.Web/9.0.0.
    return text:find('microsoft%.net%.sdk%.web["/]') ~= nil
        or text:find('microsoft%.net%.sdk%.worker["/]') ~= nil
        or text:find("<outputtype>%s*exe%s*</outputtype>") ~= nil
        or text:find("<outputtype>%s*winexe%s*</outputtype>") ~= nil
end

-- Without a solution, falls back to the project the current file belongs to.
local function find_runnable_projects()
    local start_dir = current_buffer_dir()
    local solution = find_solution(start_dir)

    local projects
    if solution then
        projects = list_solution_projects(solution)
    else
        projects = { find_nearest_project(start_dir) }
    end

    local runnable = vim.iter(projects):filter(is_runnable):totable()
    table.sort(runnable)
    return runnable
end

-- Returns the profiles `dotnet run` can use, sorted by name, each with its `name` added.
-- Empty when the project has no launchSettings.json.
local function read_launch_profiles(project)
    local path = vim.fs.joinpath(vim.fs.dirname(project), "Properties", "launchSettings.json")
    if vim.fn.filereadable(path) == 0 then return {} end

    -- luanil turns JSON nulls into nil, so `"applicationUrl": null` counts as not set.
    local options = { skip_comments = true, luanil = { object = true } }
    local ok, settings_or_error = pcall(vim.json.decode, table.concat(vim.fn.readfile(path), "\n"), options)
    if not ok then
        error("Can't read " .. path .. ": " .. settings_or_error, 0)
    end
    local settings = settings_or_error

    -- `dotnet run` only uses "Project" profiles. Others are for IIS Express, Docker and so on.
    local profiles = {}
    for name, profile in pairs(settings.profiles or {}) do
        if profile.commandName == "Project" then
            table.insert(profiles, vim.tbl_extend("force", profile, { name = name }))
        end
    end
    -- Sorted by name because the JSON decoder doesn't keep the order profiles appear in the file.
    table.sort(profiles, function(a, b) return a.name < b.name end)
    return profiles
end

-- Asks which item to use and calls on_choice with its index. With one item, uses it without asking.
local function pick(prompt, labels, on_choice)
    if #labels == 1 then
        on_choice(1)
        return
    end

    vim.ui.select(labels, { prompt = prompt }, function(_, index)
        if index then on_choice(index) end
    end)
end

-- When no error matched the error format, the whole output is shown instead, so a failed
-- build always shows its error (e.g. a missing SDK or a corrupt solution file).
local function show_build_errors(target, output_lines, succeeded)
    local title = "dotnet build " .. vim.fs.basename(target)
    vim.fn.setqflist({}, " ", { title = title, lines = output_lines, efm = BUILD_ERROR_FORMAT })

    local has_errors = vim.iter(vim.fn.getqflist()):any(function(entry) return entry.type == "e" end)
    if not succeeded and not has_errors then
        vim.fn.setqflist({}, "r", { title = title, lines = output_lines, efm = "%+G%.%#" })
    end

    -- setqflist doesn't fire this event by itself, and an open Trouble window only refreshes on it.
    vim.api.nvim_exec_autocmds("QuickFixCmdPost", { pattern = "dotnet", modeline = false })
    if not succeeded then
        vim.cmd("Trouble qflist open")
    end
end

local function finish_build(target, result, on_done)
    is_build_running = false
    local succeeded = result.code == 0
    -- The build summary repeats every error and warning.
    local output_lines = vim.list.unique(vim.split(result.stdout .. result.stderr, "\n"))
    show_build_errors(target, output_lines, succeeded)

    if succeeded then
        vim.notify("Build succeeded")
    else
        notify_error("Build failed")
    end
    if on_done then
        on_done(succeeded)
    end
end

-- Fills the quickfix list with the build's errors and warnings, and opens it in Trouble
-- when the build fails.
local function build(target, on_done)
    if is_build_running then
        vim.notify("A build is already running", vim.log.levels.WARN)
        return
    end

    local command = {
        "dotnet", "build", target,
        "-nologo",
        -- Plain console output with full paths, so the error format can parse it.
        "-tl:off", "-p:GenerateFullPaths=true",
    }
    local options = { text = true, cwd = vim.fs.dirname(target) }
    -- vim.system's exit callback runs where most editor functions aren't allowed, so it's scheduled.
    -- That also means finish_build always runs after the rest of this function.
    local on_exit = vim.schedule_wrap(function(result)
        finish_build(target, result, on_done)
    end)

    -- vim.system fails straight away when dotnet isn't on PATH.
    local ok, error_message = pcall(vim.system, command, options, on_exit)
    if not ok then
        notify_error("Can't run dotnet build: " .. error_message)
        return
    end

    -- Set only once dotnet has started, so a failed start doesn't block every later build.
    is_build_running = true
    vim.notify("Building " .. vim.fs.basename(target) .. "...")
end

-- Returns one MSBuild property of the project. Empty when the property isn't set.
-- target_framework is optional: pass it to read the property for one framework of a multi-target project.
local function read_msbuild_property(project, property, target_framework)
    local arguments = { "msbuild", project, "-getProperty:" .. property }
    if target_framework then
        table.insert(arguments, "-p:TargetFramework=" .. target_framework)
    end
    return vim.trim(run_dotnet(arguments, project))
end

-- `dotnet run` passes applicationUrl to the app as ASPNETCORE_URLS, unless the profile sets it itself.
local function profile_environment(profile)
    local env = vim.deepcopy(profile.environmentVariables or {})
    if profile.applicationUrl and not env.ASPNETCORE_URLS then
        env.ASPNETCORE_URLS = profile.applicationUrl
    end
    return env
end

-- Splits on spaces only, so an argument containing quoted spaces arrives in pieces.
local function profile_arguments(profile)
    return vim.split(profile.commandLineArgs or "", "%s+", { trimempty = true })
end

-- Asks MSBuild where the build put the DLL, then starts netcoredbg on it.
-- target_framework is nil for a project with a single framework.
-- profile is nil when the project has no launch profiles: the app then gets no extra
-- environment or arguments, as if run from the command line.
-- The profile's workingDirectory, executablePath and launchBrowser settings aren't supported.
local function start_debugger(project, profile, target_framework)
    local ok, dll_or_error = pcall(read_msbuild_property, project, "TargetPath", target_framework)
    if not ok then
        notify_error(dll_or_error)
        return
    end
    local dll = dll_or_error
    if vim.fn.filereadable(dll) == 0 then
        notify_error("Built DLL not found: " .. dll)
        return
    end

    local env = {}
    local args = {}
    if profile then
        env = profile_environment(profile)
        args = profile_arguments(profile)
    end

    require("dap").run({
        type = "coreclr",
        request = "launch",
        name = "Debug " .. vim.fn.fnamemodify(project, ":t:r"),
        program = dll,
        -- ASP.NET finds appsettings.json relative to the working directory.
        cwd = vim.fs.dirname(project),
        env = env,
        args = args,
    })
end

-- A project with several target frameworks builds one DLL each, so ask which to run.
local function choose_framework_and_debug(project, profile)
    local ok, frameworks_or_error = pcall(read_msbuild_property, project, "TargetFrameworks")
    if not ok then
        notify_error(frameworks_or_error)
        return
    end

    -- A hand-edited <TargetFrameworks> often puts each framework on its own line.
    local frameworks = vim.iter(vim.split(frameworks_or_error, ";"))
        :map(vim.trim)
        :filter(function(framework) return framework ~= "" end)
        :totable()
    if #frameworks > 1 then
        pick("Target framework", frameworks, function(index)
            start_debugger(project, profile, frameworks[index])
        end)
    else
        -- With one framework listed in <TargetFrameworks>, it's passed as the override.
        -- frameworks[1] is nil for a single <TargetFramework>, which needs no override.
        start_debugger(project, profile, frameworks[1])
    end
end

local function build_and_debug(project, profile)
    build(project, function(succeeded)
        if succeeded then
            choose_framework_and_debug(project, profile)
        end
    end)
end

function M.build_solution_or_project()
    local start_dir = current_buffer_dir()
    local target = find_solution(start_dir) or find_nearest_project(start_dir)
    if not target then
        vim.notify("No .sln, .slnx or .csproj found above this file", vim.log.levels.WARN)
        return
    end
    build(target)
end

function M.debug_project()
    -- Checked here too, so the user isn't sent through the pickers only to be refused at the end.
    if is_build_running then
        vim.notify("A build is already running", vim.log.levels.WARN)
        return
    end

    local ok, projects_or_error = pcall(find_runnable_projects)
    if not ok then
        notify_error(projects_or_error)
        return
    end
    local projects = projects_or_error
    if #projects == 0 then
        vim.notify("No runnable .NET project found (web, worker or exe)", vim.log.levels.WARN)
        return
    end

    local project_labels = vim.tbl_map(function(project) return vim.fn.fnamemodify(project, ":~:.") end, projects)
    pick("Project to debug", project_labels, function(project_index)
        local project = projects[project_index]
        local read_ok, profiles_or_error = pcall(read_launch_profiles, project)
        if not read_ok then
            notify_error(profiles_or_error)
            return
        end
        local profiles = profiles_or_error

        if #profiles == 0 then
            build_and_debug(project, nil)
        else
            local profile_names = vim.tbl_map(function(profile) return profile.name end, profiles)
            pick("Launch profile", profile_names, function(profile_index)
                build_and_debug(project, profiles[profile_index])
            end)
        end
    end)
end

return M
