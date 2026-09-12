# Known issues

Open defects, and the boundaries that are meant to be where they are.
Behavior claimed here is pinned by a case in `tests/exhaustive-deps.test.js`.

## Open

### The recommended config uses the legacy plugin shape

`configs.recommended` declares `plugins` as an array of strings, which flat config refuses outright:

```
A config object has a "plugins" key defined as an array of strings.
```

ESLint 9 is the only supported major, so the export throws wherever it is spread into a config.
The README's configuration block registers the plugin by hand and works.

### The rule file is unchecked

The vendored rule carries `@ts-nocheck`, so the compiler reads none of its 2000 lines.
A merge that mangles it still compiles, which is why the case suite and the conflict-marker grep are the gates on the sync pipeline rather than the build.
`docs/upstream-sync.md` covers that pipeline.

## Deliberate limits

### An exclusion applies to one hook call

The comment is read from the hook's own callback and from the gap between the callback and the dependency array.
A comment sitting inside a function nested in that callback belongs to the nested function, so it leaves the enclosing hook's dependencies alone.
Writing an exclusion for a nested hook therefore needs the comment inside that hook's own callback.

### A name has to match the key the rule reports

The rule collapses a property chain to whichever prefix it needs, so a hook reading two properties of one object reports the object.
An exclusion naming a longer path than the report does not match, and it is reported as unused.

### An exclusion never adds a dependency

Excluding a name the callback does not read is reported, and excluding a name the dependency array already lists is reported.
Neither changes what the hook re-runs on, because the array is what React reads.
