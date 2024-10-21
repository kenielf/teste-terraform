#!/usr/bin/env sh

# Safeguard - lualatex is mandatory for the compilation of these docs
if ! command -v lualatex; then
    exit 1
fi

# Compile twice (to make sure any tocs or bib tables are built and filled)
lualatex --shell-escape ./*.tex && \
    lualatex --shell-escape ./*.tex

# Clean temporary files
rm -rfv ./_minted*
rm -rfv ./*.aux ./*.log ./*.out ./*.toc
