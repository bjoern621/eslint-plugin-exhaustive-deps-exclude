# What an exclusion reaches

Where the rule looks for an exclusion comment, and which name in it matches which dependency.

## One hook call

The comment is read from the hook's own callback, and from the gap between the callback and the dependency array.
Both placements carry the same weight:

```javascript
useEffect(() => {
    doSomething(a, b);
    // exhaustive-deps-exclude [b]
}, [a]);

useEffect(() => {
    doSomething(a, b);
}, /* exhaustive-deps-exclude [b] */ [a]);
```

A comment inside a function nested in that callback belongs to the nested function, so it leaves the enclosing hook's dependencies alone.
An exclusion meant for a nested hook goes inside that hook's own callback.

## The name matches the reported key

An exclusion has to spell the dependency the way the rule names it in its report.
Property access is reported as the path, so the path is what an exclusion spells:

```javascript
useEffect(() => {
    connect(config.url);
    // exhaustive-deps-exclude [config.url]
}, []);
```

A hook reading two properties of one object gets one report per path, `config.port` and `config.url`, and each needs naming to be excluded.
A props object is the exception: every property of it is reported as `props`, which is the only name an exclusion can use there.

A name the rule never reports matches nothing, and it is reported as an exclusion the hook does not use.

## An exclusion only subtracts

Excluding a name the callback never reads is reported, and so is excluding a name the dependency array already lists.
Neither changes what the hook re-runs on, because the array is what React reads.
