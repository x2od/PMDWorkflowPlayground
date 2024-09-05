#!/bin/sh

# Run this BEFORE running ApexDox so all your files are set up properly.

# npx marked -i doc-assets/files/TestDataFactoryReadMe.md --gfm > "doc-assets/files/TestDataFactoryReadMe.html"
# printf '<link href="assets/styling.css" rel="stylesheet" />'  >> "doc-assets/files/TestDataFactoryReadMe.html"

# npx marked -i doc-assets/main.md --gfm > "doc-assets/main.html"

printf '<link href="assets/styling.css" rel="stylesheet" />' > "doc-assets/main.html"
echo >> "doc-assets/main.html"
npx marked -i README.md --gfm >> "doc-assets/main.html"

printf '<link href="assets/styling.css" rel="stylesheet" />' > "doc-assets/changelog.html"
echo >> "doc-assets/changelog.html"
npx marked -i CHANGELOG.md --gfm >> "doc-assets/changelog.html"
sed -i "" "s|CHANGELOG.md|changelog.html|" "doc-assets/main.html"

npm run updateHighlight