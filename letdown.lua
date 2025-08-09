-- letdown file parsing in lua, emitting html as output
local VERSION = "1.0.0-beta"

local function escape_html(s)
  return s:gsub("&", "&amp;"):gsub("<", "&lt;"):gsub(">", "&gt;")
end

local linkdefs = {}
local hashtags = {}

-- remove comments n hashtags unless inside inline code or code blocks
local function strip_comments_and_tags(text)
  local seen = {} -- don't record duplicate tags

  local out = {}
  local i = 1
  while i <= #text do
    -- code block
    if text:sub(i, i+2) == "```" then
      local block_end = text:find("\n```", i+3)
      if block_end then
        table.insert(out, text:sub(i, block_end + 3))
        i = block_end + 4
      else
        table.insert(out, text:sub(i))
        break
      end
    -- inline code
    elseif text:sub(i, i) == "`" then
      local close_tick = text:find("`", i+1)
      if close_tick then
        table.insert(out, text:sub(i, close_tick))
        i = close_tick + 1
      else
        table.insert(out, text:sub(i))
        break
      end
    else
      -- normal text
      local next_special = text:find("[`]", i)
      local segment_end = next_special and next_special - 1 or #text
      local segment = text:sub(i, segment_end)
      
      -- strip comments
      segment = segment:gsub(";;.-;;", "")
      
      -- strip hashtags but store them
      segment = segment:gsub("(%s*)#([%w_%-]+)(%s*)", function(pre, tag, post)
        if not seen[tag] then
          table.insert(hashtags, tag)
          seen[tag] = true
        end
        return pre .. post
      end)
      
      table.insert(out, segment)
      i = segment_end + 1
    end
  end
  
  return table.concat(out)
end

local function parse_spans(text)
  -- inline code
  text = text:gsub("`(.-)`", function (code)
    return "<code>" .. escape_html(code) .. "</code>"
  end)

  -- emphasis
  text = text:gsub("%*(.-)%*", "<em>%1</em>")

  -- reference-style links
  text = text:gsub("%[(.-)%]", function(label)
    local trimmed = label:match("^%s*(.-)%s*$")
    local url = linkdefs[trimmed]
    if url then
      -- links defined with a linkdef will open in a new tab
      return string.format('<a href="%s" target="_blank">%s</a>', escape_html(url), escape_html(label))
    else
      -- assume the path is "label.html" with spaces replaced by underscores
      local safe_label = trimmed:gsub("%s+", "_")
      local href = escape_html(safe_label .. ".html")
      return string.format('<a href="%s">%s</a>', href, escape_html(trimmed))
    end
  end)

  return text
end

-- emit functions for each block

local function emit_heading(line)
  if line:match("^= ") then
    return "<h1>" .. escape_html(line:sub(3)) .. "</h1>"
  elseif line:match("^== ") then
    return "<h2>" .. escape_html(line:sub(4)) .. "</h2>"
  elseif line:match("^=== ") then
    return "<h3>" .. escape_html(line:sub(5)) .. "</h3>"
  end
end

local function emit_list(block)
  local html = { "<ul>" }
  for line in block:gmatch("[^\n]+") do
    local item = line:match("^%- (.*)")
    table.insert(html, "  <li>" .. parse_spans(item or "") .. "</li>")
  end
  table.insert(html, "</ul>")
  return table.concat(html, "\n")
end

local function emit_image(line)
  local path, alt = line:match("^=>%s+(%S+)%s*(.*)")
  return string.format('<img src="%s" alt="%s">', escape_html(path or ""), escape_html(alt or ""))
end

local function emit_quote(block)
  local lines = {}
  for line in block:gmatch("[^\n]+") do
    lines[#lines + 1] = line:gsub("^> ", "")
  end
  local content = table.concat(lines, "\n")
  return string.format("<blockquote>%s</blockquote>", parse_spans(content))
end

local function emit_code(block)
  local code = block:match("^```%s*\n(.-)\n```")
  return string.format("<pre><code>%s</code></pre>", escape_html(code or ""))
end

local function emit_paragraph(block)
  return "<p>" .. parse_spans(block) .. "</p>"
end

-- parse letdown blocks from text
local function parse_letdown(text)
  -- strip comments and hashtags first
  hashtags = {}
  text = strip_comments_and_tags(text)

  local blocks = {}
  linkdefs = {} -- reset per file

  local first_h1 = nil

  -- first pass, get link definitions and remove them from text
  text = text:gsub("\n%[(.-)%]:%s+(%S+)%s*\n", function(label, url)
    linkdefs[label] = url
    return "\n"
  end)

  -- split into blocks by blank line
  local temp = {}
  for line in (text .. "\n"):gmatch("([^\n]*)\n") do
    if line:match("^%s*$") then
      if #temp > 0 then
        table.insert(blocks, table.concat(temp, "\n"))
        temp = {}
      end
    else
      table.insert(temp, line)
    end
  end
  if #temp > 0 then
    table.insert(blocks, table.concat(temp, "\n"))
  end

  -- emit html
  local html_blocks = {}
  for _, block in ipairs(blocks) do
    if block:match("^= ") then
      local h1_text = block:sub(3)
      if not first_h1 then first_h1 = h1_text end
      table.insert(html_blocks, emit_heading(block))
    elseif block:match("^== ") or block:match("^=== ") then
      table.insert(html_blocks, emit_heading(block))
    elseif block:match("^%- ") then
      table.insert(html_blocks, emit_list(block))
    elseif block:match("^=> ") then
      table.insert(html_blocks, emit_image(block))
    elseif block:match("^> ") then
      table.insert(html_blocks, emit_quote(block))
    elseif block:match("^```") then
      table.insert(html_blocks, emit_code(block))
    else
      table.insert(html_blocks, emit_paragraph(block))
    end
  end

  return table.concat(html_blocks, "\n\n"), hashtags, first_h1
end

-- cli args/flags
local input_file = nil
local help = false
local version = false
local print_stdout = false
local output_file = nil
local html_template = nil

local function print_usage()
  print("Usage: letdown.lua [-h] [-v] [-s] [-o filename] [-t template.html] file.let")
end

-- cli flag parsing
local i = 1
while i <= #arg do
  local a = arg[i]
  if a == "-h" then
    help = true
  elseif a == "-v" then
    version = true
  elseif a == "-p" then
    print_stdout = true
  elseif a == "-o" then
    i = i + 1
    output_file = arg[i]
  elseif a == "-t" then
    i = i + 1
    html_template = arg[i]
  else
    if not input_file then
      input_file = a
    else
      print("Unexpected argument: " .. a)
      print_usage()
      os.exit(1)
    end
  end
  i = i + 1
end

if help then
  print_usage()
  print(" -h                print help text")  
  print(" -v                print version info")
  print(" -o filename       write output to filename, regardless of -p tag")
  print(" -t template.html  use template.html as a template file")
  print(" -p                write output to stdout only")
  os.exit(0)
end

if version then
  print("letdown to HTML parser reference implementation\n Version " .. VERSION)
  os.exit(0)
end

-- reading input file
local f = io.open(input_file, "r")
if not f then
  print("Could not open file: " .. input_file .. "\n")
  os.exit(1)
end
local raw = f:read("*a")
f:close()

-- parse
local body, tags, first_h1 = parse_letdown(raw)

-- if html template specified, fill it
if html_template then
  local tf = io.open(html_template, "r")
  if not tf then
    print("Could not open template: " .. html_template)
    os.exit(1)
  end
  local template_str = tf:read("*a")
  tf:close()

  -- get filename without extension
  local filebase = input_file:match("([^/\\]+)%.let$")
  if not filebase then
    filebase = input_file
  end

  template_str = template_str
    :gsub("%%body", body or "")
    :gsub("%%tags", table.concat(tags, ", ") or "")
    :gsub("%%file", filebase)
    :gsub("%%h1", first_h1 or "")

  body = template_str
end

-- output
if not output_file then
  if print_stdout then
    print(body)
    os.exit(0)
  else
    -- default to just input_file.html
    output_file = input_file:gsub("%.let$", "") .. ".html" 
  end
end

-- outputting the file!
local outf = io.open(output_file, "w")
outf:write(body)
outf:close()
