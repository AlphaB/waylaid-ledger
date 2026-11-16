# Native controller compatibility

Controller support is a release requirement for every addon UI surface. Use
WoW Forever's built-in gamepad UI; no controller addon or replacement bindings
are needed. This requirement applies to future UI changes, not just this fix.

## Integration contract

`Navigation.RegisterWindow(frame, options)` registers show/hide handling and
restores windows after combat or late gamepad initialization. `options.target`
is a control or a function resolving a dynamic control; `options.scroll` is the
native scroll frame. Preserve the current visible control during refreshes.

The options canvas has its own native focus scope. Blizzard's standard
`SettingsPanel:FocusContainer` selects from `SettingsList`, which does not
contain canvas controls. Registering the canvas avoids rewriting the native
SettingsPanel focus groups. A single deferred repair handles the native
`ActivateCategory` call that follows canvas `OnShow`; it does nothing if the
page closes or another dialog takes focus. Back closes the parent Settings
window. Native window paging remains available to return to the category list.

Reports and baskets register their native lifecycle; legacy scan controls open settings.
Reports register their scroll frame for right-stick scrolling. Reopening an
already visible window explicitly transfers focus. Auction lists remain owned
by `AuctionHouseFrame`; their scrolling and targets are cleared on exit.
Virtual-row navigation resolves the new row after scrolling and preserves item
identity through price changes. Sortable headers remain actionable and reachable through native navigation.

All addon navigation mutations use Blizzard's security-wrapped entry points,
wait until out of combat, and check for the required APIs. Recovery removes all
hidden windows before adding visible ones in show order, while retaining focus
on an already active native window such as the buy screen. Mouse and keyboard
UI remain usable if native controller APIs are absent or incomplete.

## Automated release checks

```sh
python -m pip install -r requirements-dev.txt
python tools/fetch_navigation_contracts.py /tmp/wll-native-pinned
python tests/run.py --navigation-ui /tmp/wll-native-pinned --forever-navigation /tmp/wll-native-pinned
python tools/fetch_navigation_contracts.py /tmp/wll-native-latest --latest
python tests/run.py --navigation-ui /tmp/wll-native-latest --forever-navigation /tmp/wll-native-latest
python tools/package.py --navigation-ui /tmp/wll-native-pinned
```

The pinned baseline is Forever UI revision
`bebcb6bf309cf41b41bd74f8ca651e6a105b2676`, inspected 2026-11-16.
Sources are fetched as external test inputs, logged with SHA-256 hashes, and
never bundled in the addon. The source contract test executes the unmodified
native discovery, target, scroll and category-activation methods and verifies
that the navigation/lifecycle entry points retain their security wrappers.
Rendering, input devices and secure execution are simulated.

Every push/PR checks both the pinned revision and the latest Forever source
before CI produces an install artifact. Packaging also runs the regression
suite before creating a ZIP, including when run locally. Network/source failures
in the CI contract job fail the build rather than silently skipping coverage.
Repository checks do not configure remote branch protection; configure required
checks separately if release permissions must enforce them.

## In-game release checklist

Record the addon version, client build, controller and tested locales. Run this
checklist before describing a release as fully verified for native controllers:

1. Open options from the official AddOns settings list, auction-list Settings
   button, legacy controls command and minimap. Reach all six checkboxes, three
   dropdowns (including every menu choice) and three tool buttons; toggle every preference and verify persistence after reload.
   Activate options both with the UI closed and with the category already open.
2. Use Back to close settings. Use native window paging to reach settings
   categories and return. Open diagnostics and inventory reports from options,
   reopen each while still visible, and close them back to the prior window.
3. Scroll a long diagnostic/inventory report with the right stick. Verify text
   selection/keyboard behavior with the native onscreen keyboard and a physical
   keyboard. Clipboard shortcuts still depend on the client's keyboard support.
4. Navigate both auction tabs, all toolbar controls and search input. Traverse
   more rows than fit onscreen, scroll both ways, then filter to zero rows and
   clear the filter. Refresh/reprice while a row is selected and confirm that
   selection and activation refer to the same item.
5. Open and reopen a basket, navigate every requirement, and hand off to the
   native item and commodity buy screens. Verify quantity input and purchase
   confirmation remain native and require explicit user input. Close the AH
   and check that no hidden basket/list retains focus or scrolling.
6. Switch between mouse/keyboard and controller with settings, a report and a
   basket open. Enable the native controller UI after addon load. Open/close
   windows during combat where the client permits it; verify recovery afterward
   without blocked-action errors, stale focus or stolen buy-screen focus.
7. Repeat the affected paths with long translated labels and with optional
   auction addons enabled and disabled. Check controller tooltip display and
   the client's modifier support for detailed tooltips.

Automated checks passed for this change; this checklist still requires a live
WoW session. Future Blizzard changes cannot be guaranteed in advance: the latest
source check detects covered API drift, while this checklist covers behavior
that source simulation cannot establish.

Source references: [SmartNavigation](https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_GamepadSmartNavigation/SmartNavigation.lua),
[navigation utilities](https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_GamepadSmartNavigation/Utility.lua),
[frame focus manager](https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_GamepadSharedUtility/FrameControlsManager.lua),
[settings panel](https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_Settings_Shared/Blizzard_SettingsPanel.lua).
