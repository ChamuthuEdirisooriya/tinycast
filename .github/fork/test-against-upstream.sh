#!/bin/bash
# Runs the harnesses here and on the upstream commit this branch builds on, and fails only on a
# harness that fails here but passes there: some need a real display, which a runner lacks.
set -uo pipefail
BASE="$(git merge-base HEAD upstream/main)"
echo "Baseline: upstream $(git log -1 --format='%h %s' "$BASE")"
git worktree add --detach "$RUNNER_TEMP/base" "$BASE" >/dev/null || exit 1

echo "::group::Harnesses on this branch"
./Scripts/run-tests.sh 2>&1 | tee "$RUNNER_TEMP/branch.log"
echo "::endgroup::"
echo "::group::Harnesses on upstream (baseline)"
( cd "$RUNNER_TEMP/base" && ./Scripts/run-tests.sh ) 2>&1 | tee "$RUNNER_TEMP/base.log"
echo "::endgroup::"

failures() {
    local log
    log="$(perl -pe 's/\e\[[0-9;]*m//g' "$RUNNER_TEMP/$1.log")"
    if grep -q 'PASSED  All' <<<"$log"; then
        return 0
    elif grep -q 'harness(es) failed in' <<<"$log"; then
        grep 'harness(es) failed in' <<<"$log" | sed 's/.*failed in [0-9]*s: //' \
            | tr ' ' '\n' | sed '/^$/d' | sort -u
    else
        echo "__suite_did_not_finish__"
    fi
}
failures branch > "$RUNNER_TEMP/branch.failed"
failures base > "$RUNNER_TEMP/base.failed"

if grep -q '__suite_did_not_finish__' "$RUNNER_TEMP/branch.failed"; then
    echo "::error::The branch's test suite did not finish; see the log above"
    exit 1
fi
if grep -q '__suite_did_not_finish__' "$RUNNER_TEMP/base.failed"; then
    echo "::error::The upstream baseline's test suite did not finish, so there is nothing to compare with"
    exit 1
fi
for NAME in $(comm -12 "$RUNNER_TEMP/branch.failed" "$RUNNER_TEMP/base.failed"); do
    echo "::warning::$NAME fails on upstream too, so it is not counted against the branch"
done
NEW="$(comm -23 "$RUNNER_TEMP/branch.failed" "$RUNNER_TEMP/base.failed")"
if [ -n "$NEW" ]; then
    for NAME in $NEW; do echo "::error::$NAME fails on the branch but passes on upstream"; done
    exit 1
fi
echo "No harness fails on the branch that passes on upstream"
