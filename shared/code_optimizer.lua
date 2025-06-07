-- Code Optimizer Utility for Ultimate Miner
-- Analyzes and suggests code optimizations

local code_optimizer = {}

-- Common optimization patterns
local OPTIMIZATION_PATTERNS = {
    -- String concatenation in loops
    {
        pattern = "for.-do.-%.%.",
        issue = "String concatenation in loop",
        suggestion = "Use table.concat() instead",
        severity = "high"
    },
    
    -- Repeated table lookups
    {
        pattern = "([%w_]+)%.([%w_]+).-([%w_]+)%.%2",
        issue = "Repeated table lookup",
        suggestion = "Cache table value in local variable",
        severity = "medium"
    },
    
    -- Global variable access in loops
    {
        pattern = "for.-do.-[^%w]([A-Z][%w_]*)[^%w]",
        issue = "Global variable access in loop",
        suggestion = "Cache global in local variable before loop",
        severity = "medium"
    },
    
    -- Inefficient nil checks
    {
        pattern = "if%s+([%w_]+)%s*~=%s*nil%s+and%s+%1",
        issue = "Redundant nil check",
        suggestion = "Use 'if variable then' instead",
        severity = "low"
    },
    
    -- Table creation in loops
    {
        pattern = "for.-do.-{.-}",
        issue = "Table creation in loop",
        suggestion = "Create table outside loop and reuse",
        severity = "high"
    }
}

-- Performance tips
local PERFORMANCE_TIPS = {
    "Use local variables for frequently accessed values",
    "Prefer ipairs() over pairs() for array iteration",
    "Cache math functions locally for intensive calculations",
    "Use table.insert() instead of tbl[#tbl+1] for better performance",
    "Avoid creating closures in loops",
    "Use bit operations instead of math operations where possible",
    "Minimize string operations, especially concatenation",
    "Pre-allocate tables when size is known"
}

-- Analyze code for optimization opportunities
function code_optimizer.analyzeCode(code)
    local issues = {}
    local line_number = 1
    
    -- Split code into lines
    for line in code:gmatch("[^\n]+") do
        -- Check each optimization pattern
        for _, opt_pattern in ipairs(OPTIMIZATION_PATTERNS) do
            if line:match(opt_pattern.pattern) then
                table.insert(issues, {
                    line = line_number,
                    code = line:match("^%s*(.-)%s*$"),  -- Trim whitespace
                    issue = opt_pattern.issue,
                    suggestion = opt_pattern.suggestion,
                    severity = opt_pattern.severity
                })
            end
        end
        
        line_number = line_number + 1
    end
    
    return issues
end

-- Optimize table operations
function code_optimizer.optimizeTableOperations(code)
    local optimized = code
    
    -- Replace tbl[#tbl+1] with table.insert
    optimized = optimized:gsub("([%w_]+)%[#%1%s*%+%s*1%]%s*=%s*", "table.insert(%1, ")
    
    -- Replace pairs with ipairs for sequential tables
    -- This is tricky and needs context, so just flag it
    
    return optimized
end

-- Optimize string operations
function code_optimizer.optimizeStringOperations(code)
    local optimized = code
    
    -- Find string concatenation in loops
    local function replaceStringConcat(match)
        -- This would need more context to properly optimize
        return match  -- Return unchanged for now
    end
    
    return optimized
end

-- Generate optimization report
function code_optimizer.generateReport(file_content, filename)
    local report = {
        filename = filename,
        issues = code_optimizer.analyzeCode(file_content),
        line_count = 0,
        optimization_score = 100
    }
    
    -- Count lines
    for _ in file_content:gmatch("\n") do
        report.line_count = report.line_count + 1
    end
    
    -- Calculate optimization score
    local high_severity = 0
    local medium_severity = 0
    local low_severity = 0
    
    for _, issue in ipairs(report.issues) do
        if issue.severity == "high" then
            high_severity = high_severity + 1
        elseif issue.severity == "medium" then
            medium_severity = medium_severity + 1
        else
            low_severity = low_severity + 1
        end
    end
    
    -- Deduct points based on issues
    report.optimization_score = math.max(0, 
        100 - (high_severity * 10) - (medium_severity * 5) - (low_severity * 2))
    
    -- Add summary
    report.summary = {
        total_issues = #report.issues,
        high_severity = high_severity,
        medium_severity = medium_severity,
        low_severity = low_severity,
        tips = PERFORMANCE_TIPS
    }
    
    return report
end

-- Common CC:Tweaked specific optimizations
function code_optimizer.applyCCTweakedOptimizations(code)
    local optimized = code
    
    -- Cache turtle API calls
    local turtle_api_pattern = "(turtle%.%w+)%(%)([^%)]*)"
    local cached_calls = {}
    
    -- Find repeated turtle API calls
    for call in optimized:gmatch(turtle_api_pattern) do
        cached_calls[call] = (cached_calls[call] or 0) + 1
    end
    
    -- Add caching for frequently called APIs
    local cache_additions = {}
    for call, count in pairs(cached_calls) do
        if count > 3 then
            local func_name = call:match("turtle%.(%w+)")
            table.insert(cache_additions, string.format("local turtle_%s = turtle.%s", func_name, func_name))
        end
    end
    
    if #cache_additions > 0 then
        -- Add at the beginning of the file/function
        optimized = table.concat(cache_additions, "\n") .. "\n\n" .. optimized
    end
    
    -- Optimize peripheral.find calls
    optimized = optimized:gsub('peripheral%.find%("(%w+)"%)', function(type)
        return string.format('peripheral.find("%s") or error("No %s found")', type, type)
    end)
    
    -- Optimize os.pullEvent in loops
    optimized = optimized:gsub('while%s+true%s+do%s*\n%s*local%s+event.-os%.pullEvent',
        'while true do\n    local event = table.pack(os.pullEvent())')
    
    return optimized
end

-- Memory optimization suggestions
function code_optimizer.getMemoryOptimizations(code)
    local suggestions = {}
    
    -- Check for large table definitions
    if code:match("{.-\n.-\n.-\n.-\n.-}") then
        table.insert(suggestions, {
            type = "memory",
            suggestion = "Large table literal found. Consider lazy loading or external data file."
        })
    end
    
    -- Check for recursive includes
    if code:match('require%(".-"%)')then
        local requires = {}
        for module in code:gmatch('require%("(.-)"%)')do
            requires[module] = true
        end
        
        if next(requires) then
            table.insert(suggestions, {
                type = "memory",
                suggestion = "Multiple requires found. Ensure no circular dependencies."
            })
        end
    end
    
    -- Check for string building
    local concat_count = 0
    for _ in code:gmatch("%.%.") do
        concat_count = concat_count + 1
    end
    
    if concat_count > 10 then
        table.insert(suggestions, {
            type = "memory",
            suggestion = "High string concatenation count. Use table.concat for better memory usage."
        })
    end
    
    return suggestions
end

-- Analyze module for optimization
function code_optimizer.analyzeModule(module_path)
    if not fs.exists(module_path) then
        return nil, "Module not found"
    end
    
    local file = fs.open(module_path, "r")
    if not file then
        return nil, "Failed to open module"
    end
    
    local content = file.readAll()
    file.close()
    
    local report = code_optimizer.generateReport(content, module_path)
    report.memory_optimizations = code_optimizer.getMemoryOptimizations(content)
    
    return report
end

-- Batch analyze multiple files
function code_optimizer.analyzeProject(base_path)
    local results = {
        total_files = 0,
        total_issues = 0,
        total_lines = 0,
        average_score = 0,
        files = {}
    }
    
    local function scanDirectory(path)
        local files = fs.list(path)
        
        for _, file in ipairs(files) do
            local full_path = fs.combine(path, file)
            
            if fs.isDir(full_path) then
                scanDirectory(full_path)
            elseif file:match("%.lua$") then
                local report = code_optimizer.analyzeModule(full_path)
                if report then
                    results.total_files = results.total_files + 1
                    results.total_issues = results.total_issues + #report.issues
                    results.total_lines = results.total_lines + report.line_count
                    results.average_score = results.average_score + report.optimization_score
                    
                    table.insert(results.files, {
                        path = full_path,
                        score = report.optimization_score,
                        issues = #report.issues
                    })
                end
            end
        end
    end
    
    scanDirectory(base_path)
    
    if results.total_files > 0 then
        results.average_score = results.average_score / results.total_files
    end
    
    -- Sort files by score (worst first)
    table.sort(results.files, function(a, b)
        return a.score < b.score
    end)
    
    return results
end

-- Export optimization report
function code_optimizer.exportReport(report, output_file)
    local lines = {
        "Ultimate Miner Code Optimization Report",
        "=====================================",
        "",
        string.format("File: %s", report.filename),
        string.format("Lines: %d", report.line_count),
        string.format("Optimization Score: %d/100", report.optimization_score),
        "",
        "Issues Found:",
        ""
    }
    
    if #report.issues == 0 then
        table.insert(lines, "No optimization issues found!")
    else
        for _, issue in ipairs(report.issues) do
            table.insert(lines, string.format("Line %d [%s]: %s",
                issue.line, issue.severity:upper(), issue.issue))
            table.insert(lines, string.format("  Code: %s", issue.code))
            table.insert(lines, string.format("  Suggestion: %s", issue.suggestion))
            table.insert(lines, "")
        end
    end
    
    if report.memory_optimizations and #report.memory_optimizations > 0 then
        table.insert(lines, "Memory Optimization Suggestions:")
        table.insert(lines, "")
        
        for _, opt in ipairs(report.memory_optimizations) do
            table.insert(lines, "- " .. opt.suggestion)
        end
        table.insert(lines, "")
    end
    
    table.insert(lines, "General Performance Tips:")
    table.insert(lines, "")
    
    for _, tip in ipairs(PERFORMANCE_TIPS) do
        table.insert(lines, "- " .. tip)
    end
    
    -- Write to file
    local file = fs.open(output_file, "w")
    if file then
        file.write(table.concat(lines, "\n"))
        file.close()
        return true
    end
    
    return false
end

return code_optimizer