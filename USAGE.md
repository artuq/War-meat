# Prompt Generator Usage

This tool generates prompts from README files that can be used with AI assistants.

## Installation

No installation required. Just make sure you have Python 3.6+ installed.

## Usage

### Basic usage (reads README.md in current directory):
```bash
python3 prompt_generator.py
```

### Specify a different README file:
```bash
python3 prompt_generator.py path/to/README.md
```

### Save output to a file:
```bash
python3 prompt_generator.py -o output.txt
```

### With a specific README file and output:
```bash
python3 prompt_generator.py path/to/README.md -o output.txt
```

## Example

```bash
$ python3 prompt_generator.py
Based on the following README content, please help me understand the project:

# War-meat
Gra 2 

What is this project about and what are its main features?
```

## Options

- `readme_file`: Path to the README file (default: README.md)
- `-o, --output`: Output file for the generated prompt (default: stdout)
- `-h, --help`: Show help message
