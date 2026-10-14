# Font Management Tests

Open `i.cfm` for these cases:

- `fontPath.cfm`: New Font/Font Directory, registering one TrueType file.
- `fontDirectory.cfm`: the same Administrator field, registering a directory.
- `fontsList.cfm`: read-only verification and display of Font Family, Font Face,
  Postscript Name, Font Type, Usable In, and Path for user and system fonts.
- `_validate.cfm`: read-only API, fixture, and comparison validation.

## APIs And Expectations

The suite uses `CFIDE.adminapi.runtime.getFonts()`, `setFont(fontFile)`, and
`deleteFont(fontFile)`. `setFont` accepts either a file or directory path.
Each registration case compares all six list columns for the reserved fixture.
Instance-root prefixes and path separators are normalized, but a wrong
fixture path or missing metadata still fails.

Only the prime node receives the registration during the assertion phase.
CCS must replicate it; an unchanged peer fails. There is no expected-failure
tolerance or direct peer propagation to make unsupported replication pass.
Per-node writes are used during cleanup to remove only reserved fixtures.

## Fixtures And Safety

Use disposable CCS instances and deploy this category, utilities, shared
driver updates, and `testAssets/fonts` to every participating node first.
Existing registrations of either reserved family stop the test before writes:

- `CCSSuite Font File`, from the reserved `fonts/file` fixture.
- `CCSSuite Font Directory`, from the reserved `fonts/directory` fixture.

The fixture paths and font names are fixed; arbitrary input is rejected.
`cffinally` restores original per-node state after assertions, and the helper
also restores it on exceptions. Existing fonts and system registrations are
not deleted. The two tiny fonts contain original generated glyphs rather than
copies of installed fonts.

FontTools is needed only to regenerate the binary fixtures:

```powershell
python -m pip install --user fonttools
python testAssets/fonts/generateFixtures.py
```

It is not a runtime dependency of the ColdFusion tests.