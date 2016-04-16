elm-make --yes test/Test.elm --output tmp/raw-test.js &&
scripts/elm-io.sh tmp/raw-test.js tmp/test.js &&
node tmp/test.js &&
echo "Tests passed!" &&
rm tmp/raw-test.js tmp/test.js
