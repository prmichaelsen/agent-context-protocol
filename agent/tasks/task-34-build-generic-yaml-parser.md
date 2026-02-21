# Task 34: Build Generic YAML Parser with AST

**Milestone**: Future Project
**Estimated Time**: 1-2 weeks
**Dependencies**: None
**Status**: Not Started

---

## Objective

Build a truly generic YAML parser in pure POSIX shell that uses an Abstract Syntax Tree (AST) approach for efficient, flexible YAML querying with path expressions.

---

## Context

Current YAML parser (`acp.yaml.sh`) has limitations:
- ❌ Parses on every query (inefficient)
- ❌ Hard-coded for specific patterns
- ❌ Not truly generic
- ❌ Functions like `yaml_get_nested` are pattern-specific

**Vision**: Build a proper YAML parser that:
- ✅ Parses YAML once into AST
- ✅ Supports generic path expressions (`.path.to.field`, `.array[0].field`)
- ✅ Recursive tree traversal
- ✅ Works for ANY YAML structure
- ✅ Pure POSIX shell (no external dependencies)

**Research Findings**:
- yq/jq use path expressions for querying
- Proper parsers build AST first, then query
- Recursive descent parsing is standard approach
- Path expressions enable generic access

---

## Steps

### Phase 1: Research & Design (2-3 days)

#### 1. Study Existing Implementations

Research how other parsers work:
- yq path expression syntax
- jq query language
- Recursive descent parsing
- AST construction techniques

#### 2. Design AST Structure

Define how to represent YAML in shell:
```bash
# Example AST representation
# node_type: scalar, map, array
# node_value: actual value
# node_children: array of child nodes

# For: {name: "test", tags: ["a", "b"]}
# AST:
# map
#   ├─ name: scalar("test")
#   └─ tags: array
#       ├─ [0]: scalar("a")
#       └─ [1]: scalar("b")
```

#### 3. Design Path Expression Syntax

Define query syntax:
```bash
# Examples:
.name                    # Top-level key
.project.name            # Nested key
.tags[0]                 # Array index
.contents.commands[0].name  # Nested array object
```

### Phase 2: Core Parser (3-4 days)

#### 4. Implement Lexer

Tokenize YAML into lexemes:
- Keys
- Values
- Indentation levels
- Array markers (-)
- Comments (#)

#### 5. Implement Parser

Build AST from tokens:
- Recursive descent parsing
- Handle maps, arrays, scalars
- Track indentation for nesting
- Build tree structure

#### 6. Implement AST Storage

Store AST in shell variables/arrays:
- Node representation
- Parent-child relationships
- Efficient lookup

### Phase 3: Query Engine (2-3 days)

#### 7. Implement Path Parser

Parse path expressions:
- Split on dots
- Extract array indices
- Handle special characters

#### 8. Implement Tree Traversal

Navigate AST using paths:
- Recursive descent
- Array indexing
- Return values

#### 9. Implement Query Functions

Create user-facing API:
```bash
# Parse YAML into AST
yaml_parse file.yaml

# Query AST with path
yaml_query ".path.to.field"
yaml_query ".array[0].field"

# Update values
yaml_set ".path.to.field" "new value"

# Write back to file
yaml_write file.yaml
```

### Phase 4: Testing & Optimization (2-3 days)

#### 10. Comprehensive Test Suite

Test all YAML features:
- Simple maps
- Nested maps
- Simple arrays
- Object arrays
- Mixed structures
- Edge cases

#### 11. Performance Optimization

Optimize for speed:
- Cache parsed AST
- Efficient tree traversal
- Minimize subprocess calls

#### 12. Documentation

Document the parser:
- API reference
- Usage examples
- Performance characteristics
- Limitations

---

## Technical Approach

### AST Representation in Shell

```bash
# Use associative arrays (bash 4+) or indexed arrays (POSIX)
# Node format: type|value|parent|children

# Example storage:
AST_NODES=(
  "0|map||1,2"           # Root map with children 1,2
  "1|scalar|name|0|test" # Scalar: name = "test"
  "2|array|tags|0|3,4"   # Array: tags with children 3,4
  "3|scalar||2|a"        # Array element: "a"
  "4|scalar||2|b"        # Array element: "b"
)
```

### Path Expression Grammar

```
path := segment ('.' segment)*
segment := key | key '[' index ']'
key := [a-zA-Z_][a-zA-Z0-9_-]*
index := [0-9]+
```

### Query Algorithm

```
1. Parse path into segments
2. Start at root node
3. For each segment:
   a. If key: find child with matching key
   b. If array index: find nth child
   c. Move to that node
4. Return node value
```

---

## Verification

- [ ] Lexer tokenizes YAML correctly
- [ ] Parser builds valid AST
- [ ] AST represents all YAML structures
- [ ] Path expressions parse correctly
- [ ] Tree traversal finds correct nodes
- [ ] Query functions return correct values
- [ ] Update functions modify AST correctly
- [ ] Write function outputs valid YAML
- [ ] All tests passing (100+ tests)
- [ ] Performance acceptable (< 1s for typical files)
- [ ] POSIX-compliant (works in sh, bash, zsh)
- [ ] Zero external dependencies

---

## Expected Output

### New Files
- `agent/scripts/acp.yaml-parser.sh` - Generic YAML parser
- `tests/acp.yaml-parser.test.sh` - Comprehensive test suite
- `agent/design/yaml-parser-design.md` - Design document

### Enhanced API

```bash
# Parse YAML (creates AST)
yaml_parse "file.yaml"

# Query with path expressions
yaml_query ".name"                    # "test-package"
yaml_query ".project.metadata.author" # "Test Author"
yaml_query ".tags[0]"                 # "tag1"
yaml_query ".contents.commands[0].name" # "namespace.command.md"

# Update values
yaml_set ".version" "2.0.0"
yaml_set ".tags[1]" "new-tag"

# Write back
yaml_write "file.yaml"

# Backward compatible wrappers
yaml_get() { yaml_query "$2"; }
yaml_get_nested() { yaml_query "$2"; }
```

---

## Benefits

1. **Truly Generic** - Works for any YAML structure
2. **Efficient** - Parse once, query many times
3. **Maintainable** - Clean, understandable code
4. **Extensible** - Easy to add new features
5. **Powerful** - Supports complex queries
6. **Zero Dependencies** - Pure POSIX shell

---

## Challenges

1. **Complexity** - AST implementation in shell is non-trivial
2. **Performance** - Shell is slower than compiled languages
3. **Memory** - Large YAML files may be challenging
4. **POSIX Constraints** - No associative arrays in pure POSIX
5. **Testing** - Need comprehensive test coverage

---

## Alternative: Use yq

If pure shell requirement is relaxed:
- Install yq as dependency
- Wrapper functions around yq
- Full YAML support immediately
- Better performance

**Trade-off**: External dependency vs. pure shell

---

## Resources

- [yq Documentation](https://mikefarah.gitbook.io/yq/) - Path expression reference
- [jq Manual](https://stedolan.github.io/jq/manual/) - Query language inspiration
- [Recursive Descent Parsing](https://en.wikipedia.org/wiki/Recursive_descent_parser) - Parsing technique
- [AST Design](https://en.wikipedia.org/wiki/Abstract_syntax_tree) - Tree structure
- [YAML Specification](https://yaml.org/spec/1.2/spec.html) - YAML format reference

---

## Notes

- This is a significant project (1-2 weeks)
- Could be extracted as separate open-source project
- Would benefit entire shell scripting community
- Current parser works for ACP's needs (not urgent)
- Fun technical challenge!
- Consider as separate repository: `yaml-sh` or `yaml-parser-posix`

---

**Next Task**: TBD
**Estimated Completion Date**: TBD
**Potential Spin-off Project**: yaml-sh (separate repository)
