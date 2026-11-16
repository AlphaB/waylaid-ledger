# Release workflow

For completed addon changes, finish the release in the same session by default:

1. Update the addon version, both TOCs, README, and changelog as appropriate.
2. Run the Lua regression suite and build/verify the clean install ZIP.
3. Commit the changes on a `codex-` branch and open a pull request.
4. Wait for all applicable CI checks on the current PR head to pass; fix failures
   before merging. Do not bypass required checks or merge a stale revision.
5. Merge the green PR, verify the merged revision's CI, and publish a GitHub
   release with the version tag, release notes, and install ZIP built from that
   merged revision.
6. Report the PR and release links, validation, and any remaining live-client
   checks.

The user has authorized this routine PR → green checks → merge → release flow;
do not ask them to repeat the request or reconfirm these steps each session.
Honor any explicit instruction to stop before publishing or to change the scope.
