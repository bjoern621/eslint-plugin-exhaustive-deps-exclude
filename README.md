# exhaustive-deps-exclude

[![npm](https://img.shields.io/npm/v/eslint-plugin-exhaustive-deps-exclude)](https://www.npmjs.com/package/eslint-plugin-exhaustive-deps-exclude)

<!-- upstream:start -->
> **Based on** [`eslint-plugin-react-hooks@7.1.1-canary-019019be-20260911`](https://www.npmjs.com/package/eslint-plugin-react-hooks/v/7.1.1-canary-019019be-20260911)
> from React commit [`019019be403c3269e15b8d7ebefb57d30f84086b`](https://github.com/facebook/react/commit/019019be403c3269e15b8d7ebefb57d30f84086b).
<!-- upstream:end -->

## The Problem

React's `useEffect` has a simple mental model: <ins>the code inside executes whenever one of the dependencies changes</ins>. The dependency array is supposed to give developers control over _when_ effects run.

React's ESLint rule [`react-hooks/exhaustive-deps`](https://www.npmjs.com/package/eslint-plugin-react-hooks) however enforces that you include every value used inside the effect in the dependency array. But here's the catch: if you're forced to include _every_ dependency, why does the dependency array even exist? React could just auto-track everything. **Developers should have control** over what triggers re-execution.

In reality, there are legitimate cases where you _know_ a dependency shouldn't trigger a re-run. You understand your code better than the linter does.

## React's "Solution" is Overcomplicated

Consider this chat room example where you want to play a sound on new messages, but only if not muted:<br/>
(Example taken from [Removing Effect Dependencies](https://react.dev/learn/removing-effect-dependencies#do-you-want-to-read-a-value-without-reacting-to-its-changes))

```javascript
function ChatRoom({ roomId }) {
    const [messages, setMessages] = useState([]);
    const [isMuted, setIsMuted] = useState(false);

    useEffect(() => {
        const connection = createConnection();
        connection.connect();
        connection.on("message", (receivedMessage) => {
            setMessages((msgs) => [...msgs, receivedMessage]);
            if (!isMuted) {
                playSound();
            }
        });
        return () => connection.disconnect();
    }, [roomId, isMuted]); // eslint forces you to include isMuted in the dependency array
}
```

The bug: when you toggle `isMuted`, the connection **disconnects and reconnects unnecessarily**.

React introduced `useEffectEvent` as their answer to this problem:

```javascript
import { useState, useEffect, useEffectEvent } from "react";

function ChatRoom({ roomId }) {
    const [messages, setMessages] = useState([]);
    const [isMuted, setIsMuted] = useState(false);

    const onMessage = useEffectEvent((receivedMessage) => { // ╭─────────────────────────────────╮
        setMessages((msgs) => [...msgs, receivedMessage]);  // │ Whole new function with a whole │
        if (!isMuted) {                                     // │ new hook just to exclude one    │
            playSound();                                    // │ dependency...                   │
        }                                                   // ╰─────────────────────────────────╯
    });

    useEffect(() => {
        const connection = createConnection();
        connection.connect();
        connection.on("message", (receivedMessage) => {
            onMessage(receivedMessage);
        });
        return () => connection.disconnect();
    }, [roomId]);
}
```

With `useEffectEvent`, you need to (1) extract logic, (2) import another hook, and (3) restructure your code. 😮‍💨

**With this plugin, you just add one comment explaining your intent:**

```javascript
function ChatRoom({ roomId }) {
    const [messages, setMessages] = useState([]);
    const [isMuted, setIsMuted] = useState(false);

    useEffect(() => {
        const connection = createConnection();
        connection.connect();

        connection.on("message", (receivedMessage) => {
            setMessages((msgs) => [...msgs, receivedMessage]);
            if (!isMuted) {
                playSound();
            }
        });

        return () => connection.disconnect();

        // exhaustive-deps-exclude [isMuted]
    }, [roomId]);
}
```

That's it! 🥳 Clean, explicit, and you keep your code structure intact.

## When to Exclude Dependencies

### 1. WebSocket/Connection Managers

```javascript
useEffect(() => {
    websocket.on("message", (data) => {
        handleMessage(data, currentUser);
    });

    // exhaustive-deps-exclude [websocket, currentUser]
}, []);
```

You want to set up the listener _once_. Re-creating it when `currentUser` changes would cause duplicate listeners or connection issues.

### 2. Stable Callback References

```javascript
function DataTable({ onRowClick, filters }) {
    useEffect(() => {
        const data = fetchData(filters);
        data.forEach((row) => {
            row.onClick = () => onRowClick(row);
        });

        // exhaustive-deps-exclude [onRowClick]
    }, [filters]);
}
```

`onRowClick` changes reference on every parent render, but its behavior is stable. You only care about re-fetching when `filters` change.

### 3. Refs

```javascript
useEffect(() => {
    const element = elementRef.current;
    element.addEventListener("scroll", handleScroll);

    return () => element.removeEventListener("scroll", handleScroll);

    // exhaustive-deps-exclude [elementRef]
}, [handleScroll]);
```

Refs don't cause re-renders, so including them in deps is pointless.

### 4. setState Functions

```javascript
const [count, setCount] = useState(0);

useEffect(() => {
    const interval = setInterval(() => {
        setCount((c) => c + 1);
    }, 1000);

    return () => clearInterval(interval);

    // exhaustive-deps-exclude [setCount]
}, []);
```

`setCount` is stable across renders, but ESLint doesn't know that.

### 5. Event Handlers That Read Latest State

```javascript
function SearchBox({ onSearch, debounceMs }) {
    const [query, setQuery] = useState("");

    useEffect(() => {
        const handler = setTimeout(() => {
            onSearch(query);
        }, debounceMs);

        return () => clearTimeout(handler);

        // exhaustive-deps-exclude [onSearch]
    }, [query, debounceMs]);
}
```

You want to debounce based on `query` changes, not `onSearch` reference changes.

## Installation

```bash
npm install --save-dev eslint-plugin-exhaustive-deps-exclude
```

It runs on ESLint 9 and Node 22, under flat config.

### Configuration

`configs.recommended` turns React's rule off and this one on:

```javascript
// eslint.config.js
import exhaustiveDepsExclude from "eslint-plugin-exhaustive-deps-exclude";

export default [
    { files: ["**/*.{js,jsx,ts,tsx}"], ...exhaustiveDepsExclude.configs.recommended },
];
```

Registering the plugin yourself allows you to set the severity:

```javascript
// eslint.config.js
import exhaustiveDepsExclude from "eslint-plugin-exhaustive-deps-exclude";

export default [
    {
        files: ["src/**/*.{js,jsx,ts,tsx}"],
        plugins: { "exhaustive-deps-exclude": exhaustiveDepsExclude },
        rules: {
            "react-hooks/exhaustive-deps": "off",
            "exhaustive-deps-exclude/exhaustive-deps": "warn",
        },
    },
];
```

Both rules report the same missing dependencies, so leaving React's on would report each one twice.

### Usage

Add an inline comment before the closing bracket of your dependency array:

```javascript
useEffect(() => {
    // your effect code
    // exhaustive-deps-exclude [dep1, dep2, dep3]
}, [includedDep]);
```

A name in the comment spells the dependency the way the rule reports it, so a property read is excluded by its path:

```javascript
useEffect(() => {
    connect(config.url);
    // exhaustive-deps-exclude [config.url]
}, []);
```

The plugin will:

-   ✅ Check that all non-excluded dependencies are in the array
-   ✅ Ignore dependencies listed in the exclude comment
-   ✅ Warn about unnecessary exclusions (if you exclude something not used in the effect)
-   ✅ Detect conflicting inclusions/exclusions
-   ✅ Offer the exclusion comment as an editor fix, next to the fix that adds the dependency

## (Bonus:) Why not use '// eslint-ignore-next-line react-hooks/exhaustive-deps'?

Because completely disabling the rule means **zero** linting help. You could accidentally forget to include a dependency that _should_ be there, and ESLint won't catch it.

**With `eslint-disable-next-line`:**

```javascript
useEffect(() => {
    doSomething(a, b, c);
    // eslint-disable-next-line react-hooks/exhaustive-deps
}, [a]); // Missing b and c - no warning!
```

**With `exhaustive-deps-exclude`:**

```javascript
useEffect(() => {
    doSomething(a, b, c);
    // exhaustive-deps-exclude [c]
}, [a]); // ⚠️ Plugin warns: "b is used but not in deps or excluded"
```

This plugin gives you **selective exclusion** while still catching genuine mistakes. You explicitly declare which dependencies you're intentionally excluding and the plugin verifies everything else is correct.
