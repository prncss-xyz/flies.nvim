; inherits: ecma

; tag
;; open
(jsx_self_closing_element . (_) @tag_open ) @outer
;; close
(jsx_element (jsx_opening_element . (_) @tag_close (_)*) @element (_)* @protect (jsx_closing_element) ) @outer

; arrow
;; open
(arrow_function body: [
  (undefined)
  (null)
  (false)
  (true)
  (number)
  (string)
  (array)
  (identifier)
  (binary_expression)
  (call_expression)
  (parenthesized_expression)
] @arrow_open) @outer

;; close
(arrow_function body: (statement_block ((_)? @protect (return_statement (_) @arrow_close)) ) @outer)
