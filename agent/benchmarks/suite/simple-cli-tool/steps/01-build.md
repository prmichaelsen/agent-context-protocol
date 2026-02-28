Build a command-line tool called `csv2json` that converts CSV files to JSON.

Requirements:
- Create a file called `csv2json.sh` (shell script) in the current directory
- The script must be executable (`chmod +x`)
- Usage: `./csv2json.sh <input.csv>`
- It reads the CSV file specified as the first argument
- The first row of the CSV is treated as column headers
- Each subsequent row becomes a JSON object with header names as keys
- Output is a JSON array of objects printed to stdout
- If no argument is given, print usage info to stderr and exit with code 1
- If the file doesn't exist, print an error to stderr and exit with code 1

Example input (`data.csv`):
```
name,age,city
Alice,30,New York
Bob,25,London
```

Expected output:
```json
[
  {"name": "Alice", "age": "30", "city": "New York"},
  {"name": "Bob", "age": "25", "city": "London"}
]
```

You may use any tools available in a standard Linux environment (awk, sed, python3, jq, etc).
