# MathKeyboard (SwiftUI)

An iPhone math-input screen with a custom keyboard, recreated from the reference screenshots.

## Requirements
- Xcode 16 or newer (the project uses folder-synced groups, `objectVersion 77`)
- iOS 17.0+ deployment target, iPhone, portrait

## Run
1. Open `MathKeyboard.xcodeproj`.
2. Pick an iPhone simulator and press **⌘R**.

New files added under `MathKeyboard/` are picked up by Xcode automatically.

## Structure
```
MathKeyboard/
├── MathKeyboardApp.swift        App entry (forces light mode)
├── ContentView.swift            Screen layout + key action routing
├── Model/
│   ├── MathNode.swift           Expression tree (rows, symbols, structures)
│   ├── MathEditor.swift         Cursor, insert, delete, navigation (ObservableObject)
│   └── MathEvaluator.swift      Numeric evaluation for Enter
├── Display/
│   ├── MathDisplayView.swift    Grey input box
│   └── MathRowView.swift        Renders fractions, powers, roots, functions, cursor
├── Keyboard/
│   ├── KeyDefinition.swift      Tabs, key actions, page layouts
│   ├── MathKeyboardView.swift   Tab bar + 6-column grid
│   ├── LetterKeyboardView.swift abc page (QWERTY)
│   ├── KeyButton.swift          Key view + pressed style
│   └── KeyIconView.swift        Drawn glyphs (□/□, □², √□, log□ …)
├── Shared/MathShapes.swift      Radical, stretchy paren, slot box
└── Theme/Theme.swift            Colours, fonts, metrics
```

## Status
Written and reviewed without a Mac. It has **not yet been compiled or run in Xcode**, so please build it and report any errors.
