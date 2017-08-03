#!/bin/bash

set -eu

for functionFile in $(ls functions/*); do
  filename=$(basename $functionFile)
  contents=$(cat $functionFile)

  for targetFile in `ag -l "source.*functions/${filename}"`; do
    echo Inlining $functionFile into $targetFile
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
