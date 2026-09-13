Studio.Logger = Studio.Logger or {}

local levels = {
    debug = '^5DEBUG^7',
    info = '^2INFO^7',
    warn = '^3WARN^7',
    error = '^1ERROR^7'
}

local function timestamp()
    if not Config.Logging.showTimestamps then
        return ''
    end

    if type(os) ~= 'table' or type(os.date) ~= 'function' then
        return ''
    end

    return os.date('[%H:%M:%S] ')
end

local function write(level, message)
    local label = levels[level] or levels.info
    print(('%s[%s] %s %s'):format(timestamp(), Config.Logging.prefix, label, message))
end

function Studio.Logger.Debug(message)
    if Config.Debug then
        write('debug', message)
    end
end

function Studio.Logger.Info(message)
    write('info', message)
end

function Studio.Logger.Warn(message)
    write('warn', message)
end

function Studio.Logger.Error(message)
    write('error', message)
end
