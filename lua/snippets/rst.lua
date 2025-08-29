local ls = require("luasnip")
local s = ls.snippet
local t = ls.text_node
local i = ls.insert_node
local f = ls.function_node
local c = ls.choice_node
local d = ls.dynamic_node
local sn = ls.snippet_node

-- Helper to create RST snippets
local function rst_snippet(trigger, nodes, opts)
  opts = opts or {}
  opts.wordTrig = opts.wordTrig == nil and true or opts.wordTrig
  return s(trigger, nodes, opts)
end

-- RST snippets
return {
  -- :ref: snippet - trigger on :ref to expand to :ref:`|`
  rst_snippet(":ref", {
    t(":ref:`"),
    i(1),
    t("`"),
    i(0),
  }, { desc = "RST reference", trigEngine = "pattern" }),
  
  -- :doc: snippet - trigger on :doc to expand to :doc:`|`
  rst_snippet(":doc", {
    t(":doc:`"),
    i(1),
    t("`"),
    i(0),
  }, { desc = "RST document reference", trigEngine = "pattern" }),
  
  -- Section headers
  rst_snippet("h1", {
    f(function(args) return string.rep("=", #args[1][1]) end, {1}),
    t({"", ""}),
    i(1, "Title"),
    t({"", ""}),
    f(function(args) return string.rep("=", #args[1][1]) end, {1}),
    t({"", ""}),
    i(0),
  }, { desc = "RST H1 header" }),
  
  rst_snippet("h2", {
    i(1, "Section"),
    t({"", ""}),
    f(function(args) return string.rep("=", #args[1][1]) end, {1}),
    t({"", ""}),
    i(0),
  }, { desc = "RST H2 header" }),
  
  rst_snippet("h3", {
    i(1, "Subsection"),
    t({"", ""}),
    f(function(args) return string.rep("-", #args[1][1]) end, {1}),
    t({"", ""}),
    i(0),
  }, { desc = "RST H3 header" }),
  
  -- Label definition
  rst_snippet("label", {
    t(".. _"),
    i(1, "label-name"),
    t({":","",""}),
    i(0),
  }, { desc = "RST label" }),
  
  -- Code block
  rst_snippet("code", {
    t(".. code-block:: "),
    i(1, "python"),
    t({"", "", "   "}),
    i(0),
  }, { desc = "RST code block" }),
  
  -- Note/Warning/Tip admonitions
  rst_snippet("note", {
    t({".. note::", "", "   "}),
    i(0),
  }, { desc = "RST note" }),
  
  rst_snippet("warning", {
    t({".. warning::", "", "   "}),
    i(0),
  }, { desc = "RST warning" }),
  
  rst_snippet("tip", {
    t({".. tip::", "", "   "}),
    i(0),
  }, { desc = "RST tip" }),
  
  -- Inline literal
  rst_snippet("lit", {
    t("``"),
    i(1),
    t("``"),
    i(0),
  }, { desc = "RST inline literal" }),
  
  -- Inline math
  rst_snippet("math", {
    t(":math:`"),
    i(1),
    t("`"),
    i(0),
  }, { desc = "RST inline math" }),
}