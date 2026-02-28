There is a bug in the CSV-to-JSON converter: when the CSV has empty cells, the tool either crashes or produces malformed JSON.

For example, this input:
```
name,age,city
Alice,,New York
Bob,25,
```

Should produce:
```json
[
  {"name": "Alice", "age": null, "city": "New York"},
  {"name": "Bob", "age": "25", "city": null}
]
```

Fix the bug so that:
1. Empty cells in the CSV become `null` (not `""`, not missing) in the JSON output
2. The tool does not crash on CSVs with empty cells
3. All existing tests still pass after the fix
4. Add a new test case to `test_csv2json.sh` that specifically tests empty cells producing `null` values

Run the test suite after fixing to confirm everything passes.
