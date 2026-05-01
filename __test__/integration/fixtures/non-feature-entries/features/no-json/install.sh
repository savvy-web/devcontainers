#!/usr/bin/env bash
# A directory under features/ that has no devcontainer-feature.json should
# be skipped by the collect-and-filter-features.js script.
echo "this file is part of a fixture and should never be executed"
