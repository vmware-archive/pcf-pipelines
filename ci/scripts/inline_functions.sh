#!/bin/bash

set -eu

for functionFile in $(ls functions/*); do
  filename=$(basename $functionFile)
  contents=$(cat $functionFile)

  echo Inlining $functionFile

  for targetFile in $(grep -Rl "source.*functions/${filename}" --exclude ".git"); do
    echo "  - $targetFile"
    lineNumber=$(grep -n "source.*functions/${filename}" $targetFile | cut -f1 -d':')
    let "precedingLineNumber=lineNumber-1"
    let "followingLineNumber=lineNumber+1"

    tmpFile=$(mktemp)

    head -n $precedingLineNumber $targetFile > $tmpFile

    cat >> $tmpFile <<-EOF
${contents}
EOF

    tail -n +$followingLineNumber $targetFile >> $tmpFile

    mv $tmpFile $targetFile
  done
done
