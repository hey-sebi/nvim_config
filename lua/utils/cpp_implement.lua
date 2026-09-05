local M = {}

local cpp_switch = require("utils.cpp_switch")

-- Tree-sitter query to match member function declarations inside classes and structs.
-- Derived from nvim-treesitter-cpp-tools (MIT License)
local member_func_query_scm = [[
[
    (field_declaration
        [
            (function_declarator)
            (reference_declarator
                (function_declarator))
            (pointer_declarator
                (function_declarator))
            (trailing_return_type)
        ]
    )
    (declaration
        [
            (function_declarator)
            (reference_declarator
                (function_declarator))
            (pointer_declarator
                (function_declarator))
            (trailing_return_type)
        ]
    )
]@member_function
]]

local parsed_query = nil
local function get_query()
  if not parsed_query then
    parsed_query = vim.treesitter.query.parse("cpp", member_func_query_scm)
  end
  return parsed_query
end

local function get_node_text(node, bufnr)
  if not node then
    return ""
  end
  return vim.treesitter.get_node_text(node, bufnr or 0)
end

local function get_nth_parent(node, n)
  local parent = node
  for _ = 0, n do
    parent = parent:parent()
    if not parent then
      return nil
    end
  end
  return parent
end

--- Find enclosing namespaces for a given node in top-to-bottom order (e.g. {"app", "ui"})
local function find_namespaces(node, bufnr)
  local namespaces = {}
  local curr = node
  while curr do
    if curr:type() == "namespace_definition" then
      local name_node = curr:field("name")[1]
      local ns_name = name_node and get_node_text(name_node, bufnr) or ""
      if ns_name ~= "" then
        table.insert(namespaces, 1, ns_name)
      end
    end
    curr = curr:parent()
  end
  return namespaces
end

--- Extract template parameters from a template_declaration node,
--- stripping default values (e.g. typename Alloc = std::allocator<T> -> typename Alloc)
local function check_get_template_info(node, bufnr)
  local parent = node:parent()
  if not parent or parent:type() ~= "template_declaration" then
    return nil, nil
  end

  local param_list = parent:field("parameters")[1]
  if not param_list then
    return nil, nil
  end

  local typename_names = {}
  local full_params = {}
  local count = param_list:named_child_count()

  for i = 0, count - 1 do
    local param_node = param_list:named_child(i)
    local ptype = param_node:type()

    if ptype == "type_parameter_declaration" then
      local name_node = param_node:named_child(0)
      if name_node then
        table.insert(typename_names, get_node_text(name_node, bufnr))
      end
      table.insert(full_params, get_node_text(param_node, bufnr))
    elseif ptype == "optional_type_parameter_declaration" then
      local name_node = param_node:field("name")[1]
      local name = name_node and get_node_text(name_node, bufnr) or ""
      table.insert(typename_names, name)

      local parts = {}
      for j = 0, param_node:child_count() - 1 do
        local c = param_node:child(j)
        if c:type() == "=" then
          break
        end
        table.insert(parts, vim.trim(get_node_text(c, bufnr)))
      end
      table.insert(full_params, table.concat(parts, " "))
    elseif ptype == "parameter_declaration" then
      local decl = param_node:field("declarator")[1]
      if decl then
        table.insert(typename_names, get_node_text(decl, bufnr))
      end
      table.insert(full_params, get_node_text(param_node, bufnr))
    elseif ptype == "optional_parameter_declaration" then
      local decl = param_node:field("declarator")[1]
      if decl then
        table.insert(typename_names, get_node_text(decl, bufnr))
      end

      local parts = {}
      for j = 0, param_node:child_count() - 1 do
        local c = param_node:child(j)
        if c:type() == "=" then
          break
        end
        table.insert(parts, vim.trim(get_node_text(c, bufnr)))
      end
      table.insert(full_params, table.concat(parts, " "))
    end
  end

  local template_statement = "<" .. table.concat(full_params, ", ") .. ">"
  return template_statement, typename_names
end

--- Find parent class / struct hierarchy and template parameters
local function find_class_details(member_node, bufnr)
  local class_details = {}
  local cur_node = member_node
  if cur_node:parent() and cur_node:parent():type() == "template_declaration" then
    cur_node = cur_node:parent()
  end

  local class_node = cur_node:parent() and cur_node:parent():parent()
  while class_node and (class_node:type() == "class_specifier" or class_node:type() == "struct_specifier" or class_node:type() == "union_specifier") do
    local class_data = {}
    local name_field = class_node:field("name")[1]
    class_data.name = name_field and get_node_text(name_field, bufnr) or ""

    local template_stmt, params = check_get_template_info(class_node, bufnr)
    if template_stmt and params then
      class_data.class_template_statement = "template " .. template_stmt
      class_data.class_template_params = "<" .. table.concat(params, ", ") .. ">"
    end

    table.insert(class_details, class_data)
    class_node = get_nth_parent(class_node, 2)
  end

  return class_details
end

--- Strip default argument values from parameter declarations
--- (e.g. `const std::string& name = "default"` -> `const std::string& name`)
local function format_parameters_without_defaults(params_node, bufnr)
  if not params_node then
    return "()"
  end

  local params_text = {}
  local count = params_node:named_child_count()
  for i = 0, count - 1 do
    local child = params_node:named_child(i)
    if child:type() == "optional_parameter_declaration" then
      local parts = {}
      for j = 0, child:child_count() - 1 do
        local c = child:child(j)
        if c:type() == "=" then
          break
        end
        table.insert(parts, vim.trim(get_node_text(c, bufnr)))
      end
      local raw = table.concat(parts, " ")
      raw = raw:gsub("%s+([&*])%s*", "%1 ")
      table.insert(params_text, vim.trim(raw))
    else
      table.insert(params_text, vim.trim(get_node_text(child, bufnr)))
    end
  end

  return "(" .. table.concat(params_text, ", ") .. ")"
end

--- Parse a single member function declaration node into definition components
local function get_member_function_data(node, bufnr)
  -- Skip pure virtual (`= 0`), deleted (`= delete`), or defaulted (`= default`) in-class methods
  if node:field("default_value")[1] then
    return nil
  end

  local result = {
    ret_type = "",
    fun_name = "",
    params = "",
    qualifiers = "",
    class_details = nil,
    template = "",
    namespaces = {},
  }

  local templ_stmt = check_get_template_info(node, bufnr)
  if templ_stmt then
    result.template = "template " .. templ_stmt
  end

  local return_node = node:field("type")[1]
  local declarator_node = node:field("declarator")[1]
  if not declarator_node then
    return nil
  end

  if return_node then
    result.ret_type = get_node_text(return_node, bufnr)
    -- Check for type qualifiers like const
    for i = 0, node:named_child_count() - 1 do
      local child = node:named_child(i)
      if child:type() == "type_qualifier" then
        result.ret_type = get_node_text(child, bufnr) .. " " .. result.ret_type
        break
      end
    end
  end

  -- Handle pointer/reference return types attached to declarator
  if declarator_node:type() == "reference_declarator" or declarator_node:type() == "pointer_declarator" then
    local symbol = declarator_node:type() == "reference_declarator" and "&" or "*"
    result.ret_type = result.ret_type .. symbol
    declarator_node = declarator_node:named_child(0)
  end

  if not declarator_node then
    return nil
  end

  local inner_decl = declarator_node:field("declarator")[1]
  if inner_decl then
    result.fun_name = get_node_text(inner_decl, bufnr)
  else
    result.fun_name = get_node_text(declarator_node, bufnr)
  end

  local fun_params = declarator_node:field("parameters")[1]
  result.params = format_parameters_without_defaults(fun_params, bufnr)

  -- Extract qualifiers (const, noexcept, trailing return type)
  local quals = {}
  for i = 0, declarator_node:named_child_count() - 1 do
    local child = declarator_node:named_child(i)
    local ctype = child:type()
    if ctype == "type_qualifier" or ctype == "noexcept" or ctype == "trailing_return_type" then
      table.insert(quals, get_node_text(child, bufnr))
    end
  end
  result.qualifiers = #quals > 0 and (" " .. table.concat(quals, " ")) or ""

  result.class_details = find_class_details(node, bufnr)
  result.namespaces = find_namespaces(node, bufnr)

  return result
end

--- Formats a single function definition string from parsed data
local function format_definition(fun)
  local classes_name = ""
  local class_template_statements = {}

  if fun.class_details and #fun.class_details > 0 then
    for i = #fun.class_details, 1, -1 do
      local c = fun.class_details[i]
      local templ_part = c.class_template_params or ""
      classes_name = classes_name .. c.name .. templ_part .. "::"
      if c.class_template_statement then
        table.insert(class_template_statements, c.class_template_statement)
      end
    end
  end

  local template_prefix = ""
  if #class_template_statements > 0 and fun.template ~= "" then
    template_prefix = table.concat(class_template_statements, " ") .. " " .. fun.template .. "\n"
  elseif #class_template_statements > 0 then
    template_prefix = table.concat(class_template_statements, " ") .. "\n"
  elseif fun.template ~= "" then
    template_prefix = fun.template .. "\n"
  end

  local ret_part = fun.ret_type ~= "" and (fun.ret_type .. " ") or ""
  local header_line = ret_part .. classes_name .. fun.fun_name .. fun.params .. fun.qualifiers

  return template_prefix .. header_line .. "\n{\n}\n"
end

--- Find the best insertion line in the target C++ source buffer
--- Strategy:
--- 1. If buffer has existing function definitions for class_name, insert after the last one.
--- 2. If buffer has matching namespace definition, insert before its closing brace.
--- 3. If buffer has any namespace definition, insert before the innermost namespace's closing brace.
--- 4. Otherwise, insert at the end of the file.
local function find_insertion_point(target_bufnr, class_name, namespaces)
  local line_count = vim.api.nvim_buf_line_count(target_bufnr)
  if line_count == 0 or (line_count == 1 and vim.api.nvim_buf_get_lines(target_bufnr, 0, 1, false)[1] == "") then
    return 0, true -- empty buffer
  end

  local ok, parser = pcall(vim.treesitter.get_parser, target_bufnr, "cpp")
  if not ok or not parser then
    return line_count, false
  end

  local tree = parser:parse()[1]
  if not tree then
    return line_count, false
  end

  local root = tree:root()
  local last_class_func_end_row = nil
  local matching_ns_body = nil
  local innermost_ns_body = nil

  local full_ns_str = (namespaces and #namespaces > 0) and table.concat(namespaces, "::") or nil
  local innermost_ns_name = (namespaces and #namespaces > 0) and namespaces[#namespaces] or nil

  local function traverse(node)
    local ntype = node:type()
    if ntype == "function_definition" and class_name and class_name ~= "" then
      local decl = node:field("declarator")[1]
      local decl_text = decl and get_node_text(decl, target_bufnr) or ""
      if decl_text:find(class_name .. "::", 1, true) then
        local _, _, e_row, _ = node:range()
        last_class_func_end_row = e_row
      end
    elseif ntype == "namespace_definition" then
      local body = node:field("body")[1]
      if body then
        innermost_ns_body = body
        local name_node = node:field("name")[1]
        local ns_name = name_node and get_node_text(name_node, target_bufnr) or ""
        if ns_name ~= "" and (ns_name == innermost_ns_name or ns_name == full_ns_str) then
          matching_ns_body = body
        end
      end
    end

    for child in node:iter_children() do
      traverse(child)
    end
  end

  traverse(root)

  -- 1. Insert right after existing member functions of this class
  if last_class_func_end_row then
    return last_class_func_end_row + 1, false
  end

  -- 2. Insert before closing brace of matching namespace
  if matching_ns_body then
    local _, _, ns_end_row, _ = matching_ns_body:range()
    return ns_end_row, false
  end

  -- 3. Insert before closing brace of innermost namespace
  if innermost_ns_body then
    local _, _, ns_end_row, _ = innermost_ns_body:range()
    return ns_end_row, false
  end

  -- 4. Fallback: end of file
  return line_count, false
end

--- Collect all member function declarations within the given 1-indexed row range [start_line, end_line]
function M.extract_definitions(bufnr, start_line, end_line)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  local ok, parser = pcall(vim.treesitter.get_parser, bufnr, "cpp")
  if not ok or not parser then
    vim.notify("Tree-sitter C++ parser is not available for this buffer", vim.log.levels.ERROR, { title = "C++ Tools" })
    return {}
  end

  local tree = parser:parse()[1]
  if not tree then
    return {}
  end

  local query = get_query()
  local root = tree:root()

  -- Convert to 0-indexed row range
  local sel_start = (start_line or 1) - 1
  local sel_end = (end_line or vim.api.nvim_buf_line_count(bufnr)) - 1

  local matches = query:iter_matches(root, bufnr, sel_start, sel_end + 1)
  local definitions = {}

  for pattern, match in matches do
    for cid, nodes in pairs(match) do
      local node = nodes[1] or nodes
      local f_start, _, f_end, _ = node:range()
      -- Check if node overlaps with selection range
      if f_end >= sel_start and f_start <= sel_end then
        local data = get_member_function_data(node, bufnr)
        if data and data.fun_name ~= "" then
          local formatted = format_definition(data)
          local class_name = (data.class_details and #data.class_details > 0) and data.class_details[1].name or ""
          table.insert(definitions, {
            name = data.fun_name,
            code = formatted,
            class_name = class_name,
            namespaces = data.namespaces or {},
          })
        end
      end
    end
  end

  return definitions
end

--- Focuses an existing window displaying target_file, or opens a new vertical split.
local function open_or_focus_vsplit(target_file)
  local norm_target = vim.fs.normalize(target_file):lower()
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    local buf = vim.api.nvim_win_get_buf(win)
    if vim.fs.normalize(vim.api.nvim_buf_get_name(buf)):lower() == norm_target then
      vim.api.nvim_set_current_win(win)
      return win
    end
  end

  vim.cmd("vsplit " .. vim.fn.fnameescape(target_file))
  return vim.api.nvim_get_current_win()
end

--- Creates function definitions in the alternate source file from declarations in the header.
--- @param start_line? integer 1-indexed start line (defaults to cursor line)
--- @param end_line? integer 1-indexed end line (defaults to cursor line)
function M.implement(start_line, end_line)
  local src_buf = vim.api.nvim_get_current_buf()
  local header_path = vim.api.nvim_buf_get_name(src_buf)

  if not start_line or not end_line then
    local cur_row = vim.api.nvim_win_get_cursor(0)[1]
    start_line = start_line or cur_row
    end_line = end_line or cur_row
  end

  local definitions = M.extract_definitions(src_buf, start_line, end_line)
  if #definitions == 0 then
    vim.notify("No C++ member function declarations found in range", vim.log.levels.WARN, { title = "C++ Tools" })
    return
  end

  cpp_switch.resolve_and_execute(function(target_file)
    open_or_focus_vsplit(target_file)
    local target_buf = vim.api.nvim_get_current_buf()

    local primary_class = definitions[1].class_name
    local primary_namespaces = definitions[1].namespaces

    local insert_row, is_empty = find_insertion_point(target_buf, primary_class, primary_namespaces)

    local lines_to_insert = {}
    local first_body_offset = nil

    if is_empty then
      -- Add header include for new files
      local header_name = vim.fn.fnamemodify(header_path, ":t")
      table.insert(lines_to_insert, string.format('#include "%s"', header_name))
      table.insert(lines_to_insert, "")

      local has_ns = primary_namespaces and #primary_namespaces > 0
      local ns_str = has_ns and table.concat(primary_namespaces, "::") or ""

      if has_ns then
        table.insert(lines_to_insert, string.format("namespace %s {", ns_str))
        table.insert(lines_to_insert, "")
      end

      for i, def in ipairs(definitions) do
        local def_lines = vim.split(def.code, "\n")
        for j, line in ipairs(def_lines) do
          table.insert(lines_to_insert, line)
          if i == 1 and line == "{" and not first_body_offset then
            first_body_offset = #lines_to_insert
          end
        end
        if i < #definitions then
          table.insert(lines_to_insert, "")
        end
      end

      if has_ns then
        table.insert(lines_to_insert, "")
        table.insert(lines_to_insert, string.format("} // namespace %s", ns_str))
      end
    else
      table.insert(lines_to_insert, "")
      for i, def in ipairs(definitions) do
        local def_lines = vim.split(def.code, "\n")
        for j, line in ipairs(def_lines) do
          table.insert(lines_to_insert, line)
          if i == 1 and line == "{" and not first_body_offset then
            first_body_offset = #lines_to_insert
          end
        end
        if i < #definitions then
          table.insert(lines_to_insert, "")
        end
      end
    end

    -- Insert lines into target buffer
    vim.api.nvim_buf_set_lines(target_buf, insert_row, insert_row, false, lines_to_insert)

    -- Position cursor inside the first inserted function body
    local target_line = insert_row + (first_body_offset or 1) + 1
    local total_lines = vim.api.nvim_buf_line_count(target_buf)
    if target_line > total_lines then
      target_line = total_lines
    end
    vim.api.nvim_win_set_cursor(0, { target_line, 0 })

    local msg = string.format("Implemented %d function(s) in %s", #definitions, vim.fn.fnamemodify(target_file, ":t"))
    vim.notify(msg, vim.log.levels.INFO, { title = "C++ Tools" })
  end, { create_if_missing = true })
end

--- Split a qualified_identifier AST node into scopes list and the final function name
--- e.g. Outer::Inner::do_work -> scopes = {"Outer", "Inner"}, func_name = "do_work"
local function split_qualified_identifier(node, bufnr)
  local parts = {}
  local curr = node
  while curr and curr:type() == "qualified_identifier" do
    local scope = curr:field("scope")[1]
    if scope then
      table.insert(parts, get_node_text(scope, bufnr))
    end
    curr = curr:field("name")[1]
  end
  local func_name = curr and get_node_text(curr, bufnr) or ""
  return parts, func_name
end

--- Parse a function_definition AST node into an in-class declaration
local function parse_function_definition(node, bufnr)
  local is_templ = node:parent() and node:parent():type() == "template_declaration"
  local templ_node = is_templ and node:parent() or nil

  local type_node = node:field("type")[1]
  local decl_node = node:field("declarator")[1]
  if not decl_node then
    return nil
  end

  local ret_type = ""
  if type_node then
    ret_type = get_node_text(type_node, bufnr)
    for i = 0, node:named_child_count() - 1 do
      local child = node:named_child(i)
      if child:type() == "type_qualifier" then
        ret_type = get_node_text(child, bufnr) .. " " .. ret_type
        break
      end
    end
  end

  if decl_node:type() == "reference_declarator" or decl_node:type() == "pointer_declarator" then
    local symbol = decl_node:type() == "reference_declarator" and "&" or "*"
    ret_type = ret_type .. symbol
    decl_node = decl_node:named_child(0)
  end

  if not decl_node then
    return nil
  end

  local inner_decl = decl_node:field("declarator")[1]
  local scopes, func_name = {}, ""
  if inner_decl and inner_decl:type() == "qualified_identifier" then
    scopes, func_name = split_qualified_identifier(inner_decl, bufnr)
  else
    func_name = inner_decl and get_node_text(inner_decl, bufnr) or get_node_text(decl_node, bufnr)
  end

  local params_node = decl_node:field("parameters")[1]
  local params = params_node and get_node_text(params_node, bufnr) or "()"

  local quals = {}
  for i = 0, decl_node:named_child_count() - 1 do
    local child = decl_node:named_child(i)
    local ctype = child:type()
    if ctype == "type_qualifier" or ctype == "noexcept" or ctype == "trailing_return_type" then
      table.insert(quals, get_node_text(child, bufnr))
    end
  end
  local qual_str = #quals > 0 and (" " .. table.concat(quals, " ")) or ""

  local func_template = ""
  if templ_node then
    local templ_params = templ_node:field("parameters")[1]
    local templ_text = templ_params and ("template " .. get_node_text(templ_params, bufnr)) or ""
    local last_scope = scopes[#scopes] or ""
    -- If the class scope had template parameters (e.g. Container<T>), template belongs to class, not function
    if not last_scope:find("<") then
      func_template = templ_text .. "\n"
    end
  end

  local ret_part = ret_type ~= "" and (ret_type .. " ") or ""
  local decl_str = func_template .. ret_part .. func_name .. params .. qual_str .. ";"
  local class_name = scopes[#scopes] and scopes[#scopes]:gsub("<.*>", "") or ""

  return {
    class_name = class_name,
    scopes = scopes,
    func_name = func_name,
    declaration = decl_str,
    namespaces = find_namespaces(node, bufnr),
  }
end

--- Extract function definitions in a source buffer within range [start_line, end_line]
function M.extract_declarations(bufnr, start_line, end_line)
  bufnr = bufnr or vim.api.nvim_get_current_buf()
  local ok, parser = pcall(vim.treesitter.get_parser, bufnr, "cpp")
  if not ok or not parser then
    vim.notify("Tree-sitter C++ parser is not available for this buffer", vim.log.levels.ERROR, { title = "C++ Tools" })
    return {}
  end

  local tree = parser:parse()[1]
  if not tree then
    return {}
  end

  local root = tree:root()
  local sel_start = (start_line or 1) - 1
  local sel_end = (end_line or vim.api.nvim_buf_line_count(bufnr)) - 1

  local declarations = {}

  local function traverse(node)
    if node:type() == "function_definition" then
      local s_start, _, s_end, _ = node:range()
      local p = node:parent()
      if p and p:type() == "template_declaration" then
        s_start, _, _, _ = p:range()
      end

      if s_end >= sel_start and s_start <= sel_end then
        local data = parse_function_definition(node, bufnr)
        if data and data.func_name ~= "" then
          table.insert(declarations, data)
        end
      end
    end
    for child in node:iter_children() do
      traverse(child)
    end
  end

  traverse(root)
  return declarations
end

--- Recursively locate a nested class or struct by its scopes in the header AST
local function find_scoped_class(node, scopes, bufnr, depth)
  depth = depth or 1
  local target_name = scopes[depth]
  if not target_name then
    return nil
  end
  target_name = target_name:gsub("<.*>", "")

  for child in node:iter_children() do
    local t = child:type()
    if t == "class_specifier" or t == "struct_specifier" then
      local name_node = child:field("name")[1]
      local name = name_node and get_node_text(name_node, bufnr) or ""
      if name == target_name then
        if depth == #scopes then
          return child
        else
          local body = child:field("body")[1]
          if body then
            local found = find_scoped_class(body, scopes, bufnr, depth + 1)
            if found then
              return found
            end
          end
        end
      end
    end
    local found = find_scoped_class(child, scopes, bufnr, depth)
    if found then
      return found
    end
  end
  return nil
end

--- Find the best insertion point in a header buffer for a class declaration
--- Returns insert_row (0-indexed), indent string, need_public_header (boolean)
local function find_class_insertion_point(target_bufnr, scopes)
  local line_count = vim.api.nvim_buf_line_count(target_bufnr)
  local default_indent = "    "
  local ok_sw, sw = pcall(function() return vim.bo[target_bufnr].shiftwidth end)
  if ok_sw and sw and sw > 0 then
    default_indent = string.rep(" ", sw)
  end

  local ok, parser = pcall(vim.treesitter.get_parser, target_bufnr, "cpp")
  if not ok or not parser then
    return line_count, default_indent, false
  end

  local tree = parser:parse()[1]
  if not tree then
    return line_count, default_indent, false
  end

  local root = tree:root()
  local target_node = nil
  if scopes and #scopes > 0 then
    target_node = find_scoped_class(root, scopes, target_bufnr, 1)
  end

  if target_node then
    local body = target_node:field("body")[1]
    if not body then
      local _, _, end_row, _ = target_node:range()
      return end_row, default_indent, false
    end

    local is_struct = target_node:type() == "struct_specifier"
    local count = body:named_child_count()

    if count == 0 then
      local start_row, _, _, _ = body:range()
      return start_row + 1, default_indent, not is_struct
    end

    local public_idx = nil
    local next_section_idx = nil

    for i = 0, count - 1 do
      local child = body:named_child(i)
      if child:type() == "access_specifier" then
        local text = vim.trim(get_node_text(child, target_bufnr)):gsub(":", "")
        if text == "public" then
          public_idx = i
        elseif public_idx and not next_section_idx then
          next_section_idx = i
          break
        end
      end
    end

    if public_idx then
      local insert_after_child_idx = next_section_idx and (next_section_idx - 1) or (count - 1)
      local last_child = body:named_child(insert_after_child_idx)
      local _, _, end_row, _ = last_child:range()

      local lines = vim.api.nvim_buf_get_lines(target_bufnr, end_row, end_row + 1, false)
      local last_line = lines[1] or ""
      local indent = last_line:match("^(%s*)") or default_indent
      if indent == "" and insert_after_child_idx == public_idx then
        indent = default_indent
      end

      return end_row + 1, indent, false
    end

    if is_struct then
      local first_non_public = nil
      for i = 0, count - 1 do
        local child = body:named_child(i)
        if child:type() == "access_specifier" then
          first_non_public = child
          break
        end
      end

      if first_non_public then
        local start_row, _, _, _ = first_non_public:range()
        return start_row, default_indent, false
      else
        local last_child = body:named_child(count - 1)
        local _, _, end_row, _ = last_child:range()
        return end_row + 1, default_indent, false
      end
    else
      local first_child = body:named_child(0)
      local start_row, _, _, _ = first_child:range()
      return start_row, default_indent, true
    end
  end

  -- Fallback: check for include guards (#endif at file end)
  local target_lines = vim.api.nvim_buf_get_lines(target_bufnr, 0, -1, false)
  for i = #target_lines, math.max(1, #target_lines - 5), -1 do
    if target_lines[i]:match("^%s*#%s*endif") then
      return i - 1, "", false
    end
  end

  return line_count, "", false
end

--- Creates function declarations in the alternate header file from definitions in the source file.
--- @param start_line? integer 1-indexed start line (defaults to cursor line)
--- @param end_line? integer 1-indexed end line (defaults to cursor line)
function M.declare(start_line, end_line)
  local src_buf = vim.api.nvim_get_current_buf()

  if not start_line or not end_line then
    local cur_row = vim.api.nvim_win_get_cursor(0)[1]
    start_line = start_line or cur_row
    end_line = end_line or cur_row
  end

  local declarations = M.extract_declarations(src_buf, start_line, end_line)
  if #declarations == 0 then
    vim.notify("No C++ function definitions found in range", vim.log.levels.WARN, { title = "C++ Tools" })
    return
  end

  cpp_switch.resolve_and_execute(function(target_file)
    open_or_focus_vsplit(target_file)
    local target_buf = vim.api.nvim_get_current_buf()

    local line_count = vim.api.nvim_buf_line_count(target_buf)
    local is_empty = line_count == 0 or (line_count == 1 and vim.api.nvim_buf_get_lines(target_buf, 0, 1, false)[1] == "")

    local primary_scopes = declarations[1].scopes
    local primary_class = declarations[1].class_name
    local primary_namespaces = declarations[1].namespaces

    local default_indent = "    "
    local ok_sw, sw = pcall(function() return vim.bo[target_buf].shiftwidth end)
    if ok_sw and sw and sw > 0 then
      default_indent = string.rep(" ", sw)
    end

    local lines_to_insert = {}
    local first_decl_offset = nil
    local insert_row = 0

    if is_empty then
      table.insert(lines_to_insert, "#pragma once")
      table.insert(lines_to_insert, "")

      local has_ns = primary_namespaces and #primary_namespaces > 0
      local ns_str = has_ns and table.concat(primary_namespaces, "::") or ""

      if has_ns then
        table.insert(lines_to_insert, string.format("namespace %s {", ns_str))
        table.insert(lines_to_insert, "")
      end

      local class_indent = has_ns and default_indent or ""
      local member_indent = class_indent .. default_indent

      if primary_class and primary_class ~= "" then
        table.insert(lines_to_insert, string.format("%sclass %s {", class_indent, primary_class))
        table.insert(lines_to_insert, string.format("%spublic:", class_indent))
        for _, decl in ipairs(declarations) do
          local decl_lines = vim.split(decl.declaration, "\n")
          for _, line in ipairs(decl_lines) do
            table.insert(lines_to_insert, member_indent .. line)
            if not first_decl_offset then
              first_decl_offset = #lines_to_insert
            end
          end
        end
        table.insert(lines_to_insert, string.format("%s};", class_indent))
      else
        for _, decl in ipairs(declarations) do
          local decl_lines = vim.split(decl.declaration, "\n")
          for _, line in ipairs(decl_lines) do
            table.insert(lines_to_insert, class_indent .. line)
            if not first_decl_offset then
              first_decl_offset = #lines_to_insert
            end
          end
        end
      end

      if has_ns then
        table.insert(lines_to_insert, "")
        table.insert(lines_to_insert, string.format("} // namespace %s", ns_str))
      end
    else
      local i_row, indent, need_pub = find_class_insertion_point(target_buf, primary_scopes)
      insert_row = i_row
      if need_pub then
        table.insert(lines_to_insert, "public:")
      end
      for _, decl in ipairs(declarations) do
        local decl_lines = vim.split(decl.declaration, "\n")
        for _, line in ipairs(decl_lines) do
          table.insert(lines_to_insert, indent .. line)
          if not first_decl_offset then
            first_decl_offset = #lines_to_insert
          end
        end
      end
    end

    -- Insert lines into header buffer
    vim.api.nvim_buf_set_lines(target_buf, insert_row, insert_row, false, lines_to_insert)

    -- Position cursor on the first inserted declaration
    local target_line = insert_row + (first_decl_offset or 1)
    local total_lines = vim.api.nvim_buf_line_count(target_buf)
    if target_line > total_lines then
      target_line = total_lines
    end
    vim.api.nvim_win_set_cursor(0, { target_line, #default_indent })

    local msg = string.format("Declared %d function(s) in %s", #declarations, vim.fn.fnamemodify(target_file, ":t"))
    vim.notify(msg, vim.log.levels.INFO, { title = "C++ Tools" })
  end, { create_if_missing = true })
end

--- Context-aware dispatcher: checks if cursor/range is on a function definition or declaration,
--- and executes the appropriate direction.
--- @param start_line? integer 1-indexed start line (defaults to cursor line)
--- @param end_line? integer 1-indexed end line (defaults to cursor line)
function M.smart_action(start_line, end_line)
  local bufnr = vim.api.nvim_get_current_buf()
  local cur_row = vim.api.nvim_win_get_cursor(0)[1]
  start_line = start_line or cur_row
  end_line = end_line or cur_row

  local ok, parser = pcall(vim.treesitter.get_parser, bufnr, "cpp")
  if not ok or not parser then
    -- Fallback based on extension
    local ext = vim.fn.expand("%:e"):lower()
    if ext == "h" or ext == "hpp" or ext == "hh" or ext == "hxx" or ext == "inl" then
      M.implement(start_line, end_line)
    else
      M.declare(start_line, end_line)
    end
    return
  end

  local tree = parser:parse()[1]
  if not tree then
    M.implement(start_line, end_line)
    return
  end

  local root = tree:root()
  local sel_start = start_line - 1
  local sel_end = end_line - 1

  local has_definition = false
  local has_declaration = false

  local function inspect(node)
    local ntype = node:type()
    if ntype == "function_definition" then
      local s_s, _, s_e, _ = node:range()
      local p = node:parent()
      if p and p:type() == "template_declaration" then
        s_s, _, _, _ = p:range()
      end
      if s_e >= sel_start and s_s <= sel_end then
        has_definition = true
      end
    elseif ntype == "field_declaration" or (ntype == "declaration" and node:field("declarator")[1]) then
      local s_s, _, s_e, _ = node:range()
      if s_e >= sel_start and s_s <= sel_end then
        has_declaration = true
      end
    end
    for child in node:iter_children() do
      inspect(child)
      if has_definition then
        return
      end
    end
  end

  inspect(root)

  if has_definition then
    M.declare(start_line, end_line)
  elseif has_declaration then
    M.implement(start_line, end_line)
  else
    local ext = vim.fn.expand("%:e"):lower()
    if ext == "h" or ext == "hpp" or ext == "hh" or ext == "hxx" or ext == "inl" then
      M.implement(start_line, end_line)
    else
      M.declare(start_line, end_line)
    end
  end
end

-- Create user commands `:CppImplement` and `:CppDeclare`
vim.api.nvim_create_user_command("CppImplement", function(opts)
  if opts.range == 2 then
    M.implement(opts.line1, opts.line2)
  else
    M.implement()
  end
end, { range = true, desc = "Implement C++ member function(s) in alternate source file" })

vim.api.nvim_create_user_command("CppDeclare", function(opts)
  if opts.range == 2 then
    M.declare(opts.line1, opts.line2)
  else
    M.declare()
  end
end, { range = true, desc = "Declare C++ function(s) in alternate header file" })

return M
