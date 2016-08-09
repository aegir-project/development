#!/bin/bash

# Simple command looks for all repos in subdirectories, and runs `git pull` on them all.
find . -type d -name .git -exec sh -c "cd \"{}\"/../ && pwd && git pull" \;
