#!/bin/bash
#
#  Build documentation using jazzy:
#    [sudo] gem install jazzy

jazzy \
	-o "docs" \
	--sdk "iphone" \
	--module-version "1.0"
