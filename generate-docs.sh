#!/bin/bash
#
#  Build documentation using jazzy:
#    [sudo] gem install jazzy

jazzy \
	-o "docs" \
	--sdk "iphone" \
	--module-version "1.0"

# copy resources
mkdir docs/assets 2>/dev/null
cp assets/* docs/assets/

# redirect .md links to GitHub
sed -i '' 's/href="\([\/a-zA-Z\/-_\.]\{1,\}\.md\)"/href="https:\/\/github.com\/chb\/c3-pro-ios-framework\/blob\/master\/\1"/g' docs/index.html

# redirect module READMEs to GitHub
sed -i '' 's/href="\.\/Sources\/\([\/a-zA-Z]\{1,\}\)"/href="https:\/\/github.com\/chb\/c3-pro-ios-framework\/blob\/master\/Sources\/\1"/g' docs/index.html

# now sync `docs/` to `/` in the gh-pages branch
