# GFP Games

Browser-based interactive fiction and narrative games set in the Graveyard Footfall / Cat and Crow universe.

## First vertical slice

The current prototype is a Red Company historical rectification terminal.

The player:
- reviews an Authorized Record,
- inspects contradictory evidence,
- makes a ruling: AMEND, DESTROY, or REFER,
- accumulates Standing and Curiosity,
- saves progress locally in the browser.

The first case quietly introduces Dante Reed through recovered art and the phrase **DEAD HAND MATERIAL**.

## Architecture

- React + TypeScript + Vite
- Responsive layout for desktop and mobile
- Story content separated from UI code
- LocalStorage save state for the prototype

The intended long-term structure is a reusable narrative engine with individual cases supplied as data.

## Local development

```bash
npm install
npm run dev
```

## Production build

```bash
npm run build
```

The generated `dist/` directory can be deployed to any static host.
