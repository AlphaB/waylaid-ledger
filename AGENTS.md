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


## Release completion policy

For work in this repository, every completed change must end with a
published release, without an additional release prompt or confirmation from the
user. This includes code, fixes, UI, tests, documentation and instruction changes.
The user provides standing authorization to commit and push the task's changes,
create a new version tag, publish the release and upload its install ZIP using
the repository's established release destination and workflow.

- Treat releasing as part of the task, not as an optional follow-up. A local
  implementation, passing tests, a commit or a built ZIP alone is not completion.
- Check the current remote release/version before choosing the next version.
  Update version metadata and the changelog consistently; never overwrite or
  reuse an existing published version or tag.
- Run the required checks below, build and verify the install ZIP, publish the
  release with clear notes, and verify that the release and downloadable asset
  are available. End the response with the released version and release link.
- Keep unrelated workspace changes out of the release. Do not discard or
  overwrite other work to prepare it.
- Do not bypass failing checks or claim unperformed in-game checks passed.
  Record outstanding manual verification in the release notes. If a genuine
  blocker prevents release, report the specific blocker and release status;
  ask only for missing access or a decision needed to resolve it, not whether
  the user wants a release.
- An explicit user instruction to stop before release or keep a task local
  overrides this default for that task.

## Native controller support

Native WoW Forever controller support is a requirement for every UI change and
every release. Preserve mouse and keyboard operation as well.

- Route addon window lifecycle, focus and scrolling through `Navigation.lua`.
  Register new dialogs with `Navigation.RegisterWindow`, provide an initial
  useful target, and register their scroll frame when applicable.
- Keep every action reachable with the native controller UI. Check opening,
  navigation, activation, Back/close and return focus. Include empty lists,
  disabled actions, virtual/recycled rows and dynamic updates.
- Use only Blizzard's exposed security-wrapped navigation entry points. Do not
  replace native bindings, modify native internal state, or call unwrapped
  focus/selection methods. Defer native mutations during combat and support
  gamepad activation after addon load.
- Extend `tests/controller.lua` or the virtual-list/shopping checks in
  `tests/standalone.lua` for changed behavior. New dialogs must be included in
  the native discovery check, including unnamed or lazily created dialogs.
- Run `python tests/run.py`. For controller changes and releases, fetch the
  pinned and latest Forever sources with `tools/fetch_navigation_contracts.py`
  and run the suite with `--navigation-ui` for each. Do not bypass failing
  controller checks to produce a release. Package using `tools/package.py`.
- Follow `docs/CONTROLLER.md` for the live-client release checklist. Automated
  results do not prove hardware input, security/taint behavior or compatibility
  with future client versions. Record unperformed checks explicitly.

Keep unrelated existing workspace changes intact.
