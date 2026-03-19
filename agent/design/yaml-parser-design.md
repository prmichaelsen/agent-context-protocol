# Generic YAML Parser with AST Design

**Concept**: Pure POSIX shell YAML parser using Abstract Syntax Tree for efficient querying  
**Created**: 2026-02-21  
**Status**: Design Specification  

---

## Overview

A truly generic YAML parser in pure POSIX shell that builds an Abstract Syntax Tree (AST) once, then supports efficient querying via path expressions like `.path.to.field` and `.array[0].field`.

**Current Problem**: Existing `acp.yaml.sh` parser:  
- Parses on every query (inefficient)
- Hard-coded for specific patterns
- Functions like `yaml_get_nested` are pattern-specific
- Not truly generic

**Solution**: Build proper parser that:  
- Parses YAML once into AST
- Supports generic path expressions
- Uses recursive tree traversal
- Works for ANY YAML structure
- Pure POSIX shell (no external dependencies)

---

## Problem Statement

Current YAML parser limitations:
1. **Performance**: Re-parses file on every query
2. **Flexibility**: Hard-coded patterns for specific use cases
3. **Maintainability**: Adding new query patterns requires new functions
4. **Scalability**: Doesn't scale to complex YAML structures

---

## Solution

### AST-Based Architecture

```
Input YAML → Lexer → Tokens → Parser → AST → Query Engine → Results
```

**Components**:
1. **Lexer**: Tokenizes YAML into lexemes (keys, values, indentation, arrays)
2. **Parser**: Builds AST from tokens using recursive descent
3. **AST Storage**: Represents tree in shell arrays
4. **Query Engine**: Traverses AST using path expressions

---

## Implementation

### 1. AST Representation in Shell

**Node Structure**: Each node is a string with pipe-delimited fields:  
```
node_id|type|key|value|parent_id|children_ids
```

**Node Types**:
- `map` - Object/dictionary
- `array` - List/sequence
- `scalar` - Primitive value (string, number, boolean)

**Example**:
```yaml
name: test
tags:
  - tag1
  - tag2
```

**AST Representation**:
```bash
AST_NODES=(
  "0|map||root|-1|1,2"           # Root map, children: 1,2
  "1|scalar|name|test|0|"        # name: test
  "2|array|tags||0|3,4"          # tags array, children: 3,4
  "3|scalar||tag1|2|"            # Array element: tag1
  "4|scalar||tag2|2|"            # Array element: tag2
)
```

### 2. Path Expression Grammar

```
path := '.' segment ('.' segment)*
segment := key | key '[' index ']'
key := [a-zA-Z_][a-zA-Z0-9_-]*
index := [0-9]+
```

**Examples**:
- `.name` - Top-level key
- `.project.name` - Nested key
- `.tags[0]` - Array index
- `.contents.commands[0].name` - Nested array object

### 3. Lexer Design

**Tokens**:
```bash
TOKEN_KEY="key"           # YAML key (before colon)
TOKEN_VALUE="value"       # YAML value (after colon)
TOKEN_ARRAY_ITEM="item"   # Array item (after dash)
TOKEN_INDENT="indent"     # Indentation level
TOKEN_COMMENT="comment"   # Comment (after #)
```

**Lexer Algorithm**:
```
For each line:
  1. Calculate indentation level
  2. Strip comments
  3. Detect array marker (-)
  4. Split on colon (:)
  5. Emit tokens
```

### 4. Parser Design

**Recursive Descent Parsing**:
```
parse_node(tokens, indent_level):
  if current_token is KEY:
    if next_token is VALUE:
      return scalar_node(key, value)
    else:
      return map_node(key, parse_children())
  
  if current_token is ARRAY_ITEM:
    return array_node(parse_array_items())
```

**State Machine**:
- Track current indentation level
- Track parent nodes
- Build tree bottom-up

### 5. Query Engine Design

**Path Parsing**:
```bash
parse_path(".project.tags[0]"):
  segments = ["project", "tags[0]"]
  
  for segment in segments:
    if segment contains '[':
      key = "tags"
      index = 0
    else:
      key = segment
      index = null
```

**Tree Traversal**:
```bash
traverse(node_id, path_segments):
  if no segments left:
    return node_value(node_id)
  
  segment = first(path_segments)
  
  if segment has index:
    child = find_child_by_key_and_index(node_id, key, index)
  else:
    child = find_child_by_key(node_id, key)
  
  return traverse(child, rest(path_segments))
```

### 6. API Design

```bash
# Parse YAML into AST (call once)
yaml_parse "file.yaml"

# Query AST with path expressions (call many times)
yaml_query ".name"                    # "test-package"
yaml_query ".project.metadata.author" # "Test Author"
yaml_query ".tags[0]"                 # "tag1"
yaml_query ".contents.commands[0].name" # "namespace.command.md"

# Update values in AST
yaml_set ".name" "new-name"
yaml_set ".tags[1]" "new-tag"

# Write AST back to file
yaml_write "file.yaml"

# Backward compatibility wrappers
yaml_get() { yaml_query "$2"; }
yaml_get_nested() { yaml_query "$2"; }
```

---

## Benefits

1. **Performance**: Parse once, query many times (10-100x faster for multiple queries)
2. **Generic**: Works for any YAML structure without custom functions
3. **Maintainable**: Clean separation of concerns (lexer, parser, query)
4. **Extensible**: Easy to add new features (XPath-like queries, filters)
5. **Powerful**: Supports complex nested structures and arrays
6. **Zero Dependencies**: Pure POSIX shell

---

## Trade-offs

### Advantages
- ✅ Truly generic (no hard-coded patterns)
- ✅ Efficient for multiple queries
- ✅ Clean, maintainable code
- ✅ Extensible architecture
- ✅ Zero external dependencies

### Disadvantages
- ❌ Complex implementation (1-2 weeks)
- ❌ Shell performance limitations
- ❌ Memory usage for large files
- ❌ No associative arrays in pure POSIX (must use indexed arrays)
- ❌ Requires comprehensive testing

### Alternative: Use yq

If pure shell requirement is relaxed:
- Install yq as dependency
- Wrapper functions around yq
- Full YAML 1.2 support immediately
- Better performance (compiled Go binary)

**Trade-off**: External dependency vs. pure shell philosophy  

---

## Implementation Plan

### Phase 1: Core Parser (Week 1)
1. Implement lexer (tokenization)
2. Implement parser (AST construction)
3. Implement AST storage
4. Basic query support

### Phase 2: Query Engine (Week 2)
1. Path expression parser
2. Tree traversal
3. Update operations
4. Write back to file

### Phase 3: Testing & Optimization
1. Comprehensive test suite (100+ tests)
2. Performance optimization
3. Edge case handling
4. Documentation

---

## Technical Challenges

### Challenge 1: AST Storage in Shell

**Problem**: No native tree data structures in shell  

**Solution**: Use indexed arrays with node IDs:  
```bash
# Node format: id|type|key|value|parent|children
AST_NODES[0]="0|map||root|-1|1,2"
AST_NODES[1]="1|scalar|name|test|0|"
```

### Challenge 2: POSIX Constraints

**Problem**: No associative arrays in pure POSIX sh  

**Solution**: Use indexed arrays with linear search (acceptable for typical YAML files)  

### Challenge 3: Performance

**Problem**: Shell is slower than compiled languages  

**Solution**: 
- Parse once, query many times
- Cache frequently accessed nodes
- Minimize subprocess calls
- Use awk for heavy lifting

### Challenge 4: Complex YAML Features

**Problem**: YAML 1.2 has many features (anchors, aliases, multi-line strings)  

**Solution**: Start with subset (maps, arrays, scalars), extend incrementally  

---

## Success Criteria

- [ ] Parses simple maps correctly
- [ ] Parses nested maps correctly
- [ ] Parses simple arrays correctly
- [ ] Parses object arrays correctly
- [ ] Supports path expressions (`.key`, `.nested.key`, `.array[0]`)
- [ ] Query performance < 100ms for typical files
- [ ] Parse performance < 1s for typical files
- [ ] POSIX-compliant (works in sh, bash, zsh)
- [ ] Zero external dependencies
- [ ] 100+ tests passing
- [ ] Backward compatible API

---

## Future Enhancements

1. **Advanced Path Expressions**: Filters, wildcards, recursive descent
2. **YAML 1.2 Features**: Anchors, aliases, tags
3. **Streaming Parser**: Handle large files without loading into memory
4. **Pretty Printing**: Format YAML output with proper indentation
5. **Validation**: Schema validation against YAML schemas

---

## Potential Spin-off Project

This parser could be extracted as a separate open-source project:

**Project Name**: `yaml-sh` or `yaml-parser-posix`  

**Value Proposition**:
- First truly generic YAML parser in pure POSIX shell
- Zero dependencies
- Works everywhere (sh, bash, zsh, dash)
- Benefits entire shell scripting community

**Repository**: `github.com/prmichaelsen/yaml-sh`  

---

**Status**: Design Complete - Ready for Implementation  
**Recommendation**: Begin with Phase 1 (Core Parser) - implement lexer and basic AST construction  
**Estimated Effort**: 80-160 hours over 1-2 weeks  
**Priority**: Future Enhancement (current parser works for ACP needs)  
