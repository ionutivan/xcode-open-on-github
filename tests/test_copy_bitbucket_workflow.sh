#!/usr/bin/env bash

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WORKFLOW_PATH="$ROOT_DIR/quick-actions/Copy Bitbucket link to clipboard.workflow/Contents/document.wflow"
TMP_DIRS=()

cleanup() {
	if ((${#TMP_DIRS[@]} > 0)); then
		rm -rf "${TMP_DIRS[@]}"
	fi
}

make_tmp_dir() {
	local tmp_dir
	tmp_dir="$(mktemp -d)"
	TMP_DIRS+=("$tmp_dir")
	printf '%s' "$tmp_dir"
}

trap cleanup EXIT

assert_eq() {
	local expected="$1"
	local actual="$2"
	local message="$3"

	if [[ "$expected" != "$actual" ]]; then
		echo "FAIL: $message"
		echo "  expected: $expected"
		echo "  actual:   $actual"
		exit 1
	fi
}

assert_contains() {
	local haystack="$1"
	local needle="$2"
	local message="$3"

	if [[ "$haystack" != *"$needle"* ]]; then
		echo "FAIL: $message"
		echo "  missing: $needle"
		exit 1
	fi
}

extract_source() {
	plutil -extract actions.0.action.ActionParameters.source raw -o - "$WORKFLOW_PATH"
}

test_workflow_source_is_multiline() {
	local source
	source="$(extract_source)"

	if [[ "$source" != *$'\n'* ]]; then
		echo "FAIL: Workflow source should contain multiple lines"
		exit 1
	fi

	assert_contains "$source" "on run {input, parameters}" "Workflow should define a run handler"
	assert_contains "$source" "end run" "Workflow should close the run handler"
	assert_contains "$source" "on replace_text(" "Workflow should include replace_text helper"
}

workflow_build_url() {
	local active_document_path="$1"
	local start_line="$2"
	local end_line="$3"

	local active_document_dir
	active_document_dir="$(dirname "$active_document_path")"

	local repository_url
	repository_url="$(
		cd "$active_document_dir"
		git remote get-url origin 2>/dev/null || git remote -v | awk '$3 == "(fetch)" { print $2; exit }'
	)"
	repository_url="$(printf '%s' "$repository_url" | sed -E 's#^ssh://[^@]+@([^/:]+)(:[0-9]+)?/#https://\1/#; s#^git@([^:]+):#https://\1/#; s#\.git$##')"

	local active_document_file_name
	active_document_file_name="$(basename "$active_document_path")"

	local active_document_relative_dir
	active_document_relative_dir="$(cd "$active_document_dir" && git rev-parse --show-prefix)"

	local active_file_path_in_repository
	active_file_path_in_repository="/${active_document_relative_dir}${active_document_file_name}"

	local current_commit
	current_commit="$(cd "$active_document_dir" && git rev-parse HEAD)"

	local bitbucket_url
	bitbucket_url="${repository_url}/src/${current_commit}${active_file_path_in_repository}#lines-${start_line}:${end_line}"
	printf '%s' "${bitbucket_url// /%20}"
}

create_fixture_repo() {
	local repo_dir="$1"
	local remote_url="$2"

	mkdir -p "$repo_dir/Sources/My Module"
	cat > "$repo_dir/Sources/My Module/Feature File.swift" <<'EOF'
import Foundation

struct FeatureFile {
    let title = "Bitbucket"
}
EOF

	git -C "$repo_dir" init -q
	git -C "$repo_dir" add .
	git -C "$repo_dir" -c user.name='Test User' -c user.email='test@example.com' commit -q -m "Initial commit"
	git -C "$repo_dir" remote add origin "$remote_url"

	printf '%s' "$repo_dir/Sources/My Module/Feature File.swift"
}

assert_url_for_remote() {
	local remote_url="$1"
	local expected_base="$2"

	local tmp_dir
	tmp_dir="$(make_tmp_dir)"

	local repo_dir="$tmp_dir/repo"
	mkdir -p "$repo_dir"

	local active_document_path
	active_document_path="$(create_fixture_repo "$repo_dir" "$remote_url")"

	local commit
	commit="$(git -C "$repo_dir" rev-parse HEAD)"

	local expected_url
	expected_url="${expected_base}/src/${commit}/Sources/My%20Module/Feature%20File.swift#lines-3:5"

	local actual_url
	actual_url="$(workflow_build_url "$active_document_path" 3 5)"

	assert_eq "$expected_url" "$actual_url" "URL should be correctly generated for remote '$remote_url'"
}

test_workflow_source_contains_bitbucket_conventions() {
	local source
	source="$(extract_source)"

	assert_contains "$source" "#lines-" "Bitbucket line-range anchor should be used"
	assert_contains "$source" "git remote get-url origin" "Workflow should prefer the origin remote URL"
	assert_contains "$source" "sed -E 's#^ssh://[^@]+@" "Workflow should normalize ssh remotes to https"
	assert_contains "$source" '\\\\1' "Workflow should escape backreferences for AppleScript string parsing"
}

test_url_generation_for_remote_variants() {
	assert_url_for_remote "git@bitbucket.org:workspace/repository.git" "https://bitbucket.org/workspace/repository"
	assert_url_for_remote "ssh://git@bitbucket.org/workspace/repository.git" "https://bitbucket.org/workspace/repository"
	assert_url_for_remote "ssh://git@stash.example.com:7999/scm/TEAM/repository.git" "https://stash.example.com/scm/TEAM/repository"
}

main() {
	test_workflow_source_is_multiline
	test_workflow_source_contains_bitbucket_conventions
	test_url_generation_for_remote_variants

	echo "PASS: Copy Bitbucket workflow tests"
}

main "$@"
