-- letdown file parsing in lua, emitting HTML as its output

-- this one's a bit complicated, as tags and comments are extracted in the
-- first pass, UNLESS they occur in an inline code snippet or code block
local function strip_comments_and_extract_tags(text)
  local tags = {}
  local seen = {}
  local output = {}
  local i = 1

  while i <= #text do
    -- handling code blocks
    if text:sub(i, i+2) == "```" then -- check for block-level code start/end
      local block_end = text:find("\n```", i+3)
      if block_end then
        local block = text:sub(i, block_end + 2)
        table.insert(output, block)
        i = block_end + 3
      else
        -- malformed code block; treat the rest as plain text
        table.insert(output, text:sub(i))
        break
      end

    -- handling inline code
    elseif text:sub(i, i) == "`" then
      local close_tick = text:find("`", i + 1)
      if close_tick then
        local inline = text:sub(i, close_tick)
        table.insert(output, inline)
        i = close_tick + 1
      else
        table.insert(output, text:sub(i))
        break
      end
    
    -- normal text
    else
      -- process up to next backtick or code block
      local next_code = text:find("[`]", i)
      local segment_end = next_code and next_code - 1 or #text
      local segment = text:sub(i, segment_end)

      -- strip comments
      segment = segment:gsub("%%%%.-%%%%", "")

      -- extract tags
      for tag in segment:gmatch("#([%w_%-]+)") do
        if not seen[tag] then
          table.insert(tags, tag)
          seen[tag] = true
        end
      end

      -- remove tags from visible text
      segment = segment:gsub("#[%w_%-]+", "")
      
      table.insert(output, segment)
      i = segment_end + 1
    end
  end

  return table.concat(output), tags
end

-- splitting block elements
local function split_blocks(text)
  local blocks = {}
  local block = {}

  for line in (text .. "\n"):gmatch("([^\n]*)\n") do
    if line:match("^%s*$") then 
      if #block > 0 then
        table.insert(blocks, table.concat(block, "\n"))
        block = {}
      end
    else
      table.insert(block, line)
    end
  end

  if #block > 0 then
    table.insert(blocks, table.concat(block, "\n"))
  end

  return blocks
end

-- html emitting functions below VVV

-- handling html escaping
local function escape_html(text)
  return text:gsub("&", "&amp;"):gsub("<", "&lt;"):gsub(">", "&gt;")
end

-- span handling (inline code, emphasis, wikilinks, standard links)
local function parse_spans(text)
  -- `inline code`
  text = text:gsub("`(.-)`", function(code)
    return "<code>" .. escape_html(code) .. "</code>"
  end)

  -- *emphasis*
  text = text:gsub("%*(.-)%*", "<em>%1</em>")

  -- [[wiki links]]
  text = text:gsub("%[%[([^\n%]]-)%]%]", function(name)
    local clean = name:gsub("^%s+", ""):gsub("%s+$", "") -- trim
    local filename = clean:gsub("%s+", "_")
    local ext = filename:match("%.%w+$")
    if not ext then filename = filename .. ".html" end
    return string.format('<a href="%s">%s</a>', escape_html(filename), escape_html(clean))
  end)

  -- [inline link](url)
  text = text:gsub("%[([^%[%]]-)%]%((.-)%)", function(label, url)
    if label == "" then label = url end
    return string.format('<a href="%s" target="_blank">%s</a>', escape_html(url), escape_html(label))
  end)

  return text
end

local function emit_heading(line)
  local level_str = line:match("^(#+)")
  if not level_str then return nil end -- FIXME this should be unreachable?

  local level = #level_str
  if level > 3 then level = 3 end -- only 3 levels of headings; coz gemtext
  -- TODO print some kind of warning that the depth goes too far?
  
  local content = line:match("^#+%s*(.*)$") or ""
  return string.format("<h%d>%s</h%d>", level, escape_html(content), level)
end

local function emit_list(block)
  local html = {"<ul>"}
  for line in block:gmatch("[^\n]+") do
    local item = line:match("^%- (.*)")
    table.insert(html, string.format("  <li>%s</li>", parse_spans(item or "")))
  end
  table.insert(html, "</ul>")
  return table.concat(html, "\n")
end

local function emit_image(line)
  local path, alt = line:match("^=>%s*(%S+)%s+(.+)$") 
  if not path then
    path = line:match("^=>%s*(%S+)")
    alt = ""
  end
  return string.format('<img src="%s" alt="%s">', escape_html(path or ""), escape_html(alt or ""))
end

local function emit_quote(block)
  local content = block:gsub("^> ", "")
  return string.format("<blockquote>%s</blockquote>", parse_spans(content))
end

local function emit_code(block)
  local code = block:match("^```%s*\n(.-)\n```%s*$")
  return string.format("<pre><code>%s</code></pre>", escape_html(code or ""))
end

local function emit_paragraph(block)
  return string.format("<p>%s</p>", parse_spans(block))
end

-- emitting the right HTML for each block type
local function parse_block(block)
  if block:match("^#") then
    return emit_heading(block)
  elseif block:match("^%- ") then
    return emit_list(block)
  elseif block:match("^=> ") then
    return emit_image(block)
  elseif block:match("^> ") then
    return emit_quote(block)
  elseif block:match("^```") then
    return emit_code(block)
  else
    return emit_paragraph(block)
  end
end

-- wrapping html blocks in html boilerplate (DOCTYPE and such)
local function html_head(tags, title, include_meta, include_stylesheet)
  local tag_csv = table.concat(tags, ", ")

  local head = '<!DOCTYPE html>\n<html lang="en">\n<head>\n'
  head = head .. '<meta charset="UTF-8">\n<meta name="viewport" content="width=device-width, initial-scale=1.0">\n'

  if #tags > 0 and include_meta then
    head = head .. string.format('<meta name="keywords" content="%s">\n', tag_csv)
  end

  head = head .. string.format("<title>%s</title>\n", escape_html(title))

  if include_stylesheet then
    -- TODO CLI flag for specifying stylesheet path?
    head = head .. '<link rel="stylesheet" type="text/css" href="style.css">\n'
  end

  head = head .. "</head>\n\n"
  return head
end

-- main parse function
local function parse_letdown(raw_text, filename)
  local text, tags = strip_comments_and_extract_tags(raw_text)
  local blocks = split_blocks(text)
  local html_blocks = {}

  local title = nil -- grabbing title from first h1

  for _, block in ipairs(blocks) do
    if not title and block:match("^#%s+") then
      title = block:match("^#%s+(.*)") 
    end

    table.insert(html_blocks, parse_block(block))
  end

  -- fallback to filename for title
  if not title and filename then
    title = filename:match("([^/\\]+)%.%w+$") or filename -- strip path and extension
  end

  return table.concat(html_blocks, "\n\n"), tags, title
end

-- parsing CLI flags
local flags = {
  tag_footer = true,
  help = false,
  meta_tags = true,
  stylesheet = true,
  boilerplate = true,
  print_stdout = false,
  output_file = nil,
}
local input_file = nil

local i = 1
while i <= #arg do
  local a = arg[i]
  if a == "-t" then flags.tag_footer = false
  elseif a == "-h" then flags.help = true
  elseif a == "-m" then flags.meta_tags = false
  elseif a == "-s" then flags.stylesheet = false
  elseif a == "-b" then
    flags.boilerplate = false
    flags.meta_tags = false
  elseif a == "-p" then flags.print_stdout = true
  elseif a == "-o" then
    i = i + 1
    if not arg[i] then
      io.stderr:write("[ERROR] -o flag requires a filename.\n")
      os.exit(1)
    end
    flags.output_file = arg[i]
  elseif a:match("%.let$") or a:match("%.letdown$") then input_file = a
  else
    io.stderr:write("Unknown argument: " .. a .. "\n")
    os.exit(1)
  end
  i = i + 1
end

-- print help information
if flags.help then
  print("Usage: lua letdown.lua [-h] [-t] [-m] [-s] [-b] [-p] [-o filename] file.let")
  print(" -h           print help text")  
  print(' -t           disable <p class="tags"> tag')
  print(' -m           disable <meta name="keywords" tag')
  print(' -s           disable <link rel="stylesheet"> tag')
  print(" -b           only output text inside <body> tag")
  print(" -p           print output to stdout rather than writing to a file")
  print(" -o filename  write output to filename, regardless of -p flag\n")
end

-- ensure input file provided
if not input_file then
  io.stderr:write("[ERROR] No input file provided\n")
  io.stderr:write("Usage: lua letdown.lua [-h] [-t] [-m] [-s] [-b] [-p] [-o filename] file.let\n")
  os.exit(1)
end

-- read input
local file = io.open(input_file, "r")
if not file then
  io.stderr:write("Could not open file: " .. input_file .. "\n")
  os.exit(1)
end
local raw = file:read("*a")
file:close()

-- parsing letdown
local body, tags, title = parse_letdown(raw)
local output = body

-- adding footer
if flags.tag_footer then
  local footer = ""
  if tags and #tags > 0 then
    footer = '\n\n<p class="tags">Keywords: <em>' .. table.concat(tags, ", ") .. '</em></p>\n'
  end
  output = output .. footer
end

-- adding boilerplate
if flags.boilerplate then
  local head = html_head(tags, title, flags.meta_tags, flags.stylesheet)
  output = head .. output
  output = output .. "\n</body>\n</html>\n"
end

if flags.print_stdout then
  print(output)
end

if flags.output_file then
  -- write to file, regardless of -p flag
  local f = io.open(flags.output_file, "w")
  f:write(output)
  f:close()
else
  -- write to file only if -p flag not present
  if not flags.print_stdout then
    local base = input_file:match("([^/\\]+)%.let$") or input_file:match("([^/\\]+)%.letdown$")
    local f = io.open(base .. ".html", "w")
    f:write(output)
    f:close()
  end
end
