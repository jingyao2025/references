#!/bin/bash
# pagetext.sh <pdf> <first> [last]  -> pdftotext -layout text of the page range (good for tables)
pdf="$1"; f="$2"; l="${3:-$2}"
pdftotext -layout -f "$f" -l "$l" "$pdf" - | grep -v -E "Downloaded from|EBSCO Publishing|legal\.ebsco|^ *All rights reserved\. May not be reproduced|This content downloaded from|about\.jstor\.org/terms"
