#!/bin/bash
#
#  Build documentation using jazzy:
#    [sudo] gem install jazzy

jazzy \
	-a "C3-PRO" \
	-u "http://c3-pro.chip.org" \
	-m "C3PRO" \
	-g "https://github.com/chb/c3-pro-ios-framework.git" \
	-r "http://chb.github.io/c3-pro-ios-framework" \
	-o "docs" \
	--module-version "1.0"
