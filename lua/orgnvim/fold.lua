local vim = vim
local api = vim.api

-- Returns the line numbers of each header in the current buffer.
-- The values in the returned table for each line number are the "nest level" of
-- that header (how deeply nested it is).
local function headers_in_current_buffer(end_line)
    -- TODO: until_line + 1 ? I don't think so . . .
    local lines = api.nvim_buf_get_lines(0, 0, end_line, false)
    local headers = {}

    for i, v in ipairs(lines) do
        local _, count = string.gsub(v, "%*", "")
        local _, whitespaces = string.gsub(v, "^%s+", "")

        if count > 0 and whitespaces == 0 then
            -- However many times the `*` character appears is the "nest level"
            -- of the header.
            headers[i] = count
        end
    end

    return headers
end

-- Returns the line of the nearest header above `line_num`.
-- TODO(smolck): Maybe take `headers` as an arg?
local function nearest_header_line_num(line_num)
    local headers = headers_in_current_buffer(line_num)

    local nearest_header_index
    local min_abs
    for i, _ in pairs(headers) do
        if not min_abs then
            min_abs = math.abs(i - line_num)
            nearest_header_index = i
        elseif math.abs(i - line_num) < min_abs then
            min_abs = math.abs(i - line_num)
            nearest_header_index = i
        end
    end

    return nearest_header_index
end

local function indent(line_num)
    -- See https://learnvimscriptthehardway.stevelosh.com/chapters/49.html#an-indentation-level-helper
    return vim.fn.indent(line_number) / api.nvim_get_option('shiftwidth')
end

-- Returns the line number of the next non-blank line.
local function next_non_blank_line_num(line_num)
    local lines = api.nvim_buf_get_lines(0, line_num, -1, false)
    for i, v in ipairs(lines) do
        -- `^%s+$` matches any whitespace chars (including newlines), then the
        -- end of the string. If `string.find` can't find this pattern then it
        -- returns nil, in this case meaning the line is not blank.
        if (not string.find(v, "^%s+$")) and not (v == '') then
            -- Add `line_num` to account for getting only the lines starting at
            -- `line_num` with `nvim_buf_get_lines`
            return i + line_num
        end
    end

    return nil
end

local function parent_header_line(line_num)
    local headers = headers_in_current_buffer(line_num + 1)

    if not vim.tbl_contains(vim.tbl_keys(headers), line_num) then
        return nil
    elseif headers[line_num] == 1 then
        return line_num
    end

    local parent_headers = vim.tbl_keys(
        vim.tbl_filter(function(indent_level) return (indent_level == 1) end, headers))

    local keys = vim.tbl_keys(parent_headers)
    return parent_headers[keys[#keys]]
end

local function end_of_header(line_num)
    local headers = headers_in_current_buffer(-1)
    if not vim.tbl_contains(vim.tbl_keys(headers), line_num) then
        return nil
    end

    local header_indent = headers[line_num]
    local parent_headers = {}
    for line, indent_level in pairs(headers_in_current_buffer(-1)) do
        if indent_level == header_indent and line ~= line_num then
            parent_headers[line] = indent_level
        end
    end

    local header_starts = vim.tbl_keys(parent_headers)

    return header_starts[1]
end

-- TODO: Handle if there isn't a fold (header) maybe
local function org_toggle_fold()
    -- TODO: Maybe not best way to get line?
    local current_line = api.nvim_win_get_cursor(0)[1]
    local foldclosed = vim.fn.foldclosed(api.nvim_win_get_cursor(0)[1])

    if foldclosed ~= -1 then
        api.nvim_command('normal zo')
    else
        api.nvim_command('normal zO')
        -- for line, _ in pairs(headers_in_current_buffer(end_of_header(current_line) - 1)) do
        --     vim.fn.cursor({line, 0})
        --     api.nvim_command('normal zo')
        -- end
        -- vim.fn.cursor({current_line, 0})
    end
end

local function org_fold_text()
    local fold_start_line = vim.fn.getline(vim.v.foldstart)

    -- Remove any starting whitespaces or `*` characters from string.
    local fold_text, _ = string.gsub(fold_start_line, "^[%*%s]+", "")
    local _, count = string.gsub(fold_start_line, "%*", "")

    return string.rep(' ', count - 1) .. "* " .. fold_text .. "..."
end

local function org_indent()
    local line_num = vim.v.lnum

    if string.find(vim.fn.getline(line_num), "^%s+$") or (v == '') then
        return '-1'
    end

    local headers = headers_in_current_buffer(line_num)
    if headers[line_num] then
        return '>' .. (headers[line_num] + 1)
    end

    nearest_header_nest_level = headers[nearest_header_line_num(line_num)]
    if nearest_header_nest_level then
        return tostring(nearest_header_nest_level + 1)
    end

    return '0'
end

return {
    org_indent = org_indent,
    org_fold_text = org_fold_text,
    org_toggle_fold = org_toggle_fold,
    end_of_header = end_of_header,
}
