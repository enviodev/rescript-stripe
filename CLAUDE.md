# Claude Code Guidelines

## Package Manager

This project uses **pnpm**. Always use `pnpm` instead of `npm` or `yarn`:

```bash
pnpm install
pnpm run build
pnpm test
```

## Build

```bash
pnpm run build   # Compile ReScript
pnpm run res     # Watch mode
```

## Testing

```bash
pnpm test        # Run ava tests
```
