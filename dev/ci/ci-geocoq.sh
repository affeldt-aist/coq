#!/usr/bin/env bash

ci_dir="$(dirname "$0")"
. "${ci_dir}/ci-common.sh"

git_download geocoq

( cd "${CI_BUILD_DIR}/geocoq" && ./configure.sh && make )
