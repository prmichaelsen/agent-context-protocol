Add a test script called `test_csv2json.sh` that tests the CSV-to-JSON converter.

Requirements:
- Create `test_csv2json.sh` in the current directory
- The script must be executable (`chmod +x`)
- It should test at least these scenarios:
  1. **Valid CSV**: A normal CSV with headers and multiple rows produces correct JSON
  2. **Single row**: A CSV with only headers and one data row works correctly
  3. **Empty file**: An empty CSV file (0 bytes) is handled gracefully (no crash)
  4. **Missing file**: Running `./csv2json.sh nonexistent.csv` prints an error and exits with code 1
  5. **No arguments**: Running `./csv2json.sh` with no arguments prints usage and exits with code 1
  6. **Special characters**: A CSV with commas in quoted fields (e.g., `"New York, NY"`) is handled

For each test:
- Create temporary test CSV files as needed
- Run `./csv2json.sh` on them
- Check the exit code and output
- Print PASS or FAIL for each test
- At the end, print a summary: "X/Y tests passed"
- Exit with code 0 if all tests pass, 1 if any fail
- Clean up temporary files after tests

The test script should be self-contained and runnable with `bash test_csv2json.sh`.
