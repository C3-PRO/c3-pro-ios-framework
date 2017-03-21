#!/usr/bin/env python3
#
#  Find all localizable strings, used in code as indicated by PATTERN

import io
import re
import sys
import glob

# the reference language - 1st argument, defaults to "en"
REFERENCE = sys.argv[1] if len(sys.argv) > 1 else 'en'
REFERENCE_FILE = '{}.lproj/C3PRO.strings'.format(REFERENCE)

# the 1st group must capture the actual string
#PATTERN = re.compile(r'"((([^"])|(\\"))+?)".c3_localized')
# TODO: how to zip past '\"'?
PATTERN = re.compile(r'"([^"]+?)".c3_localized')
# TODO: extract the comments if this form is used: .c3_localized("Start Consent button title")


def parse_into(filepath, into):
	with open(filepath, 'r') as handle:
		text = handle.read()
		for res in re.finditer(PATTERN, text):
			if res is not None:
				into.add(res.group(1))


if '__main__' == __name__:
	found = set()
	
	# tests
	if False:
		tests = [
			'let str = "1 Hello".c3_localized',
			'let str = "2 Hello (World)".c3_localized',
			'let str = "3 Hello \"World\"".c3_localized',
			'let str = "The \("4 Hello".c3_localized) and \("5 World".c3_localized)"'
			'let bar = "Hello"\nfunction(is: true)\nlet two = "6 World".c3_localized'
		]
		for test in tests:
			for res in re.finditer(PATTERN, test):
				print(res.group(1) if res else None)
		sys.exit(0)
	
	# loop all implementation files
	for filepath in glob.glob("Sources/*/*.swift"):
		parse_into(filepath, found)
	
	# look at Localizable.strings
	existing = {}
	with io.open(REFERENCE_FILE, 'r', encoding='utf-8') as handle:
		for line in handle:
			line = line.strip()
			if len(line) > 0:
				parts = line.split('" = "')
				if 2 == len(parts):
					key = parts[0][1:]
					existing[key] = line
	
	# show all, alphabetically ordered
	for string in sorted(found, key=lambda s: s.lower()):
		if string in existing:
			print(existing[string])
		else:
			print('"{}" = "{}";'.format(string, string))

