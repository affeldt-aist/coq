#!/usr/bin/env bash

ci_dir="$(dirname "$0")"
. "${ci_dir}/ci-common.sh"

git_download hott

( cd "${CI_BUILD_DIR}/hott" && make && make validate )
