#!/usr/bin/env python3
"""
Prompt Generator - Generate prompts from README files
"""

import sys
import argparse


def generate_prompt_from_readme(readme_path):
    """
    Generate a prompt from a README file.
    
    Args:
        readme_path: Path to the README file
        
    Returns:
        Generated prompt as a string
    """
    try:
        with open(readme_path, 'r', encoding='utf-8') as f:
            content = f.read()
    except FileNotFoundError:
        print(f"Error: README file not found at {readme_path}", file=sys.stderr)
        return None
    except Exception as e:
        print(f"Error reading README file: {e}", file=sys.stderr)
        return None
    
    if not content.strip():
        print("Error: README file is empty", file=sys.stderr)
        return None
    
    # Generate a prompt based on the README content
    prompt = f"""Based on the following README content, please help me understand the project:

{content}

What is this project about and what are its main features?"""
    
    return prompt


def main():
    """Main entry point for the prompt generator."""
    parser = argparse.ArgumentParser(
        description='Generate prompts from README files'
    )
    parser.add_argument(
        'readme_file',
        nargs='?',
        default='README.md',
        help='Path to the README file (default: README.md)'
    )
    parser.add_argument(
        '-o', '--output',
        help='Output file for the generated prompt (default: stdout)'
    )
    
    args = parser.parse_args()
    
    prompt = generate_prompt_from_readme(args.readme_file)
    
    if prompt is None:
        sys.exit(1)
    
    if args.output:
        try:
            with open(args.output, 'w', encoding='utf-8') as f:
                f.write(prompt)
            print(f"Prompt written to {args.output}")
        except Exception as e:
            print(f"Error writing to output file: {e}", file=sys.stderr)
            sys.exit(1)
    else:
        print(prompt)
    
    return 0


if __name__ == '__main__':
    sys.exit(main())
