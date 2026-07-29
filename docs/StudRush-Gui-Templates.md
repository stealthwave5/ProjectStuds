# Stud Rush - GUI template spec (Agent G deliverable, contract §8)

Exact instance trees for every Gui template in contract §4. The Studio build in
Place1 (`ReplicatedStorage.Assets.Gui.*`) is generated from THIS document.

```
ReplicatedStorage.Assets/
  Gui/
    Hud/         TopHudPaneTemplate, HudSideButtonsPaneTemplate,
                 UpgradesPaneTemplate, ShopPaneTemplate, ToastPaneTemplate
    Components/  StatPillPaneTemplate, SideButtonPaneTemplate,
                 UpgradeRowPaneTemplate, BuyButtonPaneTemplate,
                 CloseButtonPaneTemplate, ShopItemButtonPaneTemplate
```

## Global conventions (apply everywhere unless a node says otherwise)

- **Every template root is a `Frame`** named exactly like the template
  (flat, globally-unique asset name - `Assets:Clone("StatPillPaneTemplate")`).
  Button panes get an invisible `ButtonSurface` ImageButton injected at runtime
  by `ButtonModel`, so button templates are plain Frames too - **never**
  TextButtons/ImageButtons.
- Instance **names inside one template are unique** (including UICorner /
  UIStroke / UIListLayout helpers). Names in **bold** are indexed by the pane's
  `Instances` map - misnaming any of them errors at pane construction.
- All GuiObjects: `BorderSizePixel = 0`.
- All TextLabels: `BackgroundTransparency = 1`, `RichText = false`,
  `TextScaled = false`, `TextWrapped = false` unless noted.
- Unspecified properties = Roblox defaults (`Visible = true`, `ZIndex = 1`,
  `Rotation = 0`, `ClipsDescendants = false`, `AnchorPoint = 0,0`, etc.).
- UIStroke default `ApplyStrokeMode`: `Border` on Frames, `Contextual` (text
  outline) on TextLabels - each stroke below states its mode explicitly.
- Colors are the `GuiStyles` palette (single source of truth -
  `Client/Modules/Gui/GuiStyles.luau`):

| Palette name | RGB |
|---|---|
| TextDark | 44, 56, 86 |
| Stroke (navy) | 34, 44, 72 |
| Panel | 247, 243, 234 |
| PanelAlt (white) | 255, 255, 255 |
| FillTrack | 226, 220, 208 |
| Green | 86, 196, 72 |
| Red | 232, 72, 66 |
| Blue | 64, 156, 255 |
| Orange | 255, 146, 52 |
| Purple | 170, 96, 242 |
| Gold | 255, 200, 64 |
| TextWhite | 255, 255, 255 |

- Fonts: `FredokaOne` (titles/numbers on colored surfaces), `GothamBlack`
  (icons/section labels), `GothamBold` (body). Set via the legacy `Font`
  property (e.g. `Font = Enum.Font.FredokaOne`).
- Text placeholder values below are overwritten by code at runtime; build them
  in anyway so the template previews sensibly in Studio.

---

## Components

### StatPillPaneTemplate  (`Assets/Gui/Components`)

Used by `StatPillPane` (`Instances`: `PillDesign`, `PillStroke`, `PillIcon`,
`PillText`, `PillFillTrack`, `PillFill`).

```
StatPillPaneTemplate            Frame
│   AnchorPoint (0, 0) · Position (0, 0, 0, 0) · Size (0, 200, 0, 54)
│   BackgroundTransparency 1
├── PillDesign                  Frame          ← code scales/pops this
│   │   AnchorPoint (0.5, 0.5) · Position (0.5, 0, 0.5, 0) · Size (1, 0, 1, 0)
│   │   BackgroundColor3 (247, 243, 234)  [Panel] · BackgroundTransparency 0
│   ├── PillCorner              UICorner       CornerRadius (0, 16)
│   ├── PillStroke              UIStroke       Color (34, 44, 72) · Thickness 3 · ApplyStrokeMode Border
│   ├── PillIcon                TextLabel      ← emoji icon
│   │       AnchorPoint (0, 0.5) · Position (0, 10, 0.5, 0) · Size (0, 34, 0, 34)
│   │       Font GothamBlack · TextSize 24 · Text "💰" · TextColor3 (44, 56, 86)
│   ├── PillText                TextLabel
│   │       AnchorPoint (0, 0.5) · Position (0, 50, 0.5, 0) · Size (1, -60, 1, 0)
│   │       Font FredokaOne · TextSize 22 · Text "$1,234" · TextColor3 (44, 56, 86)
│   │       TextXAlignment Left · TextYAlignment Center
│   └── PillFillTrack           Frame          ← thin bar along pill bottom (code toggles Visible)
│       │   AnchorPoint (0, 1) · Position (0, 12, 1, -7) · Size (1, -24, 0, 5)
│       │   BackgroundColor3 (226, 220, 208)  [FillTrack] · BackgroundTransparency 0.35
│       ├── PillFillTrackCorner UICorner       CornerRadius (0, 3)
│       └── PillFill            Frame          ← code drives X-scale + accent color
│           │   AnchorPoint (0, 0) · Position (0, 0, 0, 0) · Size (0, 0, 1, 0)
│           │   BackgroundColor3 (86, 196, 72)  [Green]
│           └── PillFillCorner  UICorner       CornerRadius (0, 3)
```

### SideButtonPaneTemplate  (`Assets/Gui/Components`)

Used by `SideButtonPane` (`Instances`: `SideDesign`, `SideStroke`, `SideIcon`,
`SideTitle`, `SideCost`).

```
SideButtonPaneTemplate          Frame
│   AnchorPoint (0, 0) · Position (0, 0, 0, 0) · Size (0, 160, 0, 64)
│   BackgroundTransparency 1
└── SideDesign                  Frame          ← code scales + recolors (accent per button)
    │   AnchorPoint (0.5, 0.5) · Position (0.5, 0, 0.5, 0) · Size (1, 0, 1, 0)
    │   BackgroundColor3 (64, 156, 255)  [Blue placeholder] · BackgroundTransparency 0
    ├── SideCorner              UICorner       CornerRadius (0, 14)
    ├── SideStroke              UIStroke       Color (34, 44, 72) · Thickness 3 · ApplyStrokeMode Border
    ├── SideIcon                TextLabel
    │       AnchorPoint (0, 0.5) · Position (0, 8, 0.5, 0) · Size (0, 36, 0, 36)
    │       Font GothamBlack · TextSize 26 · Text "📈" · TextColor3 (255, 255, 255)
    ├── SideTitle               TextLabel
    │       AnchorPoint (0, 0) · Position (0, 50, 0, 8) · Size (1, -58, 0, 26)
    │       Font FredokaOne · TextSize 20 · Text "Upgrades" · TextColor3 (255, 255, 255)
    │       TextXAlignment Left · TextYAlignment Center
    └── SideCost                TextLabel      ← optional cost line (code toggles Visible/Text)
            AnchorPoint (0, 0) · Position (0, 50, 0, 34) · Size (1, -58, 0, 20)
            Font GothamBold · TextSize 14 · Text "$10K" · TextColor3 (255, 255, 255)
            TextXAlignment Left · TextYAlignment Center
```

### CloseButtonPaneTemplate  (`Assets/Gui/Components`)

Used by `CloseButtonPane` (`Instances`: `CloseDesign`, `CloseStroke`,
`CloseIcon`).

```
CloseButtonPaneTemplate         Frame
│   AnchorPoint (0, 0) · Position (0, 0, 0, 0) · Size (0, 44, 0, 44)
│   BackgroundTransparency 1
└── CloseDesign                 Frame          ← code scales + brightens on hover
    │   AnchorPoint (0.5, 0.5) · Position (0.5, 0, 0.5, 0) · Size (1, 0, 1, 0)
    │   BackgroundColor3 (232, 72, 66)  [Red] · BackgroundTransparency 0
    ├── CloseCorner             UICorner       CornerRadius (0, 12)
    ├── CloseStroke             UIStroke       Color (34, 44, 72) · Thickness 3 · ApplyStrokeMode Border
    └── CloseIcon               TextLabel
            AnchorPoint (0, 0) · Position (0, 0, 0, 0) · Size (1, 0, 1, 0)
            Font FredokaOne · TextSize 24 · Text "✕" · TextColor3 (255, 255, 255)
            TextXAlignment Center · TextYAlignment Center
```

### BuyButtonPaneTemplate  (`Assets/Gui/Components`)

Used by `BuyButtonPane` (`Instances`: `BuyDesign`, `BuyStroke`, `BuyLabel`).

```
BuyButtonPaneTemplate           Frame
│   AnchorPoint (0, 0) · Position (0, 0, 0, 0) · Size (0, 110, 0, 44)
│   BackgroundTransparency 1
└── BuyDesign                   Frame          ← code recolors (green ↔ gray when disabled/MAX)
    │   AnchorPoint (0.5, 0.5) · Position (0.5, 0, 0.5, 0) · Size (1, 0, 1, 0)
    │   BackgroundColor3 (86, 196, 72)  [Green] · BackgroundTransparency 0
    ├── BuyCorner               UICorner       CornerRadius (0, 10)
    ├── BuyStroke               UIStroke       Color (34, 44, 72) · Thickness 3 · ApplyStrokeMode Border
    └── BuyLabel                TextLabel      ← cost text or "MAX"
            AnchorPoint (0, 0) · Position (0, 0, 0, 0) · Size (1, 0, 1, 0)
            Font FredokaOne · TextSize 18 · Text "$410" · TextColor3 (255, 255, 255)
            TextXAlignment Center · TextYAlignment Center
```

### UpgradeRowPaneTemplate  (`Assets/Gui/Components`)

Used by `UpgradeRowPane` (`Instances`: `RowIconBadge`, `RowIcon`, `RowName`,
`RowLevel`, `RowProgressTrack`, `RowProgressFill`, `RowBuySlot`). The
`BuyButtonPane` is cloned by code into `RowBuySlot` at runtime.

```
UpgradeRowPaneTemplate          Frame          ← white card; code fades its BackgroundTransparency
│   AnchorPoint (0, 0) · Position (0, 0, 0, 0) · Size (0, 420, 0, 72)
│   BackgroundColor3 (255, 255, 255)  [PanelAlt] · BackgroundTransparency 0
├── RowCorner                   UICorner       CornerRadius (0, 12)
├── RowIconBadge                Frame          ← accent-colored, set by code per row
│   │   AnchorPoint (0, 0.5) · Position (0, 12, 0.5, 0) · Size (0, 48, 0, 48)
│   │   BackgroundColor3 (64, 156, 255)  [Blue placeholder] · BackgroundTransparency 0
│   ├── RowIconBadgeCorner      UICorner       CornerRadius (0, 12)
│   └── RowIcon                 TextLabel
│           AnchorPoint (0, 0) · Position (0, 0, 0, 0) · Size (1, 0, 1, 0)
│           Font GothamBlack · TextSize 26 · Text "⚡" · TextColor3 (255, 255, 255)
│           TextXAlignment Center · TextYAlignment Center
├── RowName                     TextLabel
│       AnchorPoint (0, 0) · Position (0, 72, 0, 10) · Size (0, 160, 0, 24)
│       Font FredokaOne · TextSize 20 · Text "Speed" · TextColor3 (44, 56, 86)
│       TextXAlignment Left · TextYAlignment Center
├── RowLevel                    TextLabel
│       AnchorPoint (0, 0) · Position (0, 72, 0, 36) · Size (0, 160, 0, 18)
│       Font GothamBold · TextSize 14 · Text "Lv 3/10" · TextColor3 (44, 56, 86)
│       TextXAlignment Left · TextYAlignment Center
├── RowProgressTrack            Frame
│   │   AnchorPoint (0, 0.5) · Position (0, 240, 0.5, 0) · Size (0, 60, 0, 8)
│   │   BackgroundColor3 (226, 220, 208)  [FillTrack] · BackgroundTransparency 0.35
│   ├── RowProgressTrackCorner  UICorner       CornerRadius (0, 4)
│   └── RowProgressFill         Frame          ← code drives X-scale (level/max spring) + accent
│       │   AnchorPoint (0, 0) · Position (0, 0, 0, 0) · Size (0, 0, 1, 0)
│       │   BackgroundColor3 (64, 156, 255)  [Blue placeholder]
│       └── RowProgressFillCorner UICorner     CornerRadius (0, 4)
└── RowBuySlot                  Frame          ← empty slot, BuyButtonPane parented here by code
        AnchorPoint (1, 0.5) · Position (1, -12, 0.5, 0) · Size (0, 110, 0, 44)
        BackgroundTransparency 1
```

### ShopItemButtonPaneTemplate  (`Assets/Gui/Components`)

Used by `ShopItemButtonPane` (`Instances`: `ShopItemDesign`, `ShopItemStroke`,
`ShopItemTitle`, `ShopItemSubtitle`). Note: text children use **scale-based**
Y positions because the same template is stretched wide as the featured pass
button (440×96) and used square as a cash pack (150×150).

```
ShopItemButtonPaneTemplate      Frame
│   AnchorPoint (0, 0) · Position (0, 0, 0, 0) · Size (0, 150, 0, 150)
│   BackgroundTransparency 1
└── ShopItemDesign              Frame          ← code recolors (accent / green when owned)
    │   AnchorPoint (0.5, 0.5) · Position (0.5, 0, 0.5, 0) · Size (1, 0, 1, 0)
    │   BackgroundColor3 (170, 96, 242)  [Purple placeholder] · BackgroundTransparency 0
    ├── ShopItemCorner          UICorner       CornerRadius (0, 16)
    ├── ShopItemStroke          UIStroke       Color (34, 44, 72) · Thickness 3 · ApplyStrokeMode Border
    ├── ShopItemTitle           TextLabel
    │       AnchorPoint (0, 0) · Position (0, 10, 0.1, 0) · Size (1, -20, 0.45, 0)
    │       Font FredokaOne · TextSize 22 · Text "2x Cash" · TextColor3 (255, 255, 255)
    │       TextXAlignment Center · TextYAlignment Center · TextWrapped true
    └── ShopItemSubtitle        TextLabel
            AnchorPoint (0, 0) · Position (0, 10, 0.58, 0) · Size (1, -20, 0.3, 0)
            Font GothamBold · TextSize 15 · Text "+$10,000" · TextColor3 (255, 255, 255)
            TextXAlignment Center · TextYAlignment Center · TextWrapped true
```

---

## Hud

### TopHudPaneTemplate  (`Assets/Gui/Hud`)

Used by `TopHudPane` (`Instances`: `PillRow`). The three `StatPillPane` clones
are parented into `PillRow` by code with LayoutOrder 1/2/3.

```
TopHudPaneTemplate              Frame          ← top-center row; code slides it up while hidden
│   AnchorPoint (0.5, 0) · Position (0.5, 0, 0, 12) · Size (0, 640, 0, 60)
│   BackgroundTransparency 1
└── PillRow                     Frame
    │   AnchorPoint (0, 0) · Position (0, 0, 0, 0) · Size (1, 0, 1, 0)
    │   BackgroundTransparency 1
    └── PillRowLayout           UIListLayout
            FillDirection Horizontal · HorizontalAlignment Center
            VerticalAlignment Center · Padding (0, 12) · SortOrder LayoutOrder
```

### HudSideButtonsPaneTemplate  (`Assets/Gui/Hud`)

Used by `HudSideButtonsPane` (`Instances`: `SideButtonList`). The three
`SideButtonPane` clones are parented into `SideButtonList` by code with
LayoutOrder 1/2/3.

```
HudSideButtonsPaneTemplate      Frame          ← left-center stack; code slides it left while hidden
│   AnchorPoint (0, 0.5) · Position (0, 16, 0.5, 0) · Size (0, 170, 0, 240)
│   BackgroundTransparency 1
└── SideButtonList              Frame
    │   AnchorPoint (0, 0) · Position (0, 0, 0, 0) · Size (1, 0, 1, 0)
    │   BackgroundTransparency 1
    └── SideButtonListLayout    UIListLayout
            FillDirection Vertical · HorizontalAlignment Left
            VerticalAlignment Center · Padding (0, 12) · SortOrder LayoutOrder
```

### UpgradesPaneTemplate  (`Assets/Gui/Hud`)

Used by `UpgradesPane` (`Instances`: `UpgradesPanel`, `UpgradesStroke`,
`UpgradesTitleBar`, `UpgradesTitle`, `UpgradesCloseSlot`, `UpgradesRowList`,
`UpgradesMessage`). `CloseButtonPane` goes into `UpgradesCloseSlot`, three
`UpgradeRowPane` clones go into `UpgradesRowList` - all at runtime.

```
UpgradesPaneTemplate            Frame          ← invisible centered anchor; panel pops inside it
│   AnchorPoint (0.5, 0.5) · Position (0.5, 0, 0.5, 0) · Size (0, 480, 0, 420)
│   BackgroundTransparency 1
└── UpgradesPanel               Frame          ← code scale-pops this via spring
    │   AnchorPoint (0.5, 0.5) · Position (0.5, 0, 0.5, 0) · Size (1, 0, 1, 0)
    │   BackgroundColor3 (247, 243, 234)  [Panel] · BackgroundTransparency 0
    ├── UpgradesPanelCorner     UICorner       CornerRadius (0, 20)
    ├── UpgradesStroke          UIStroke       Color (34, 44, 72) · Thickness 4 · ApplyStrokeMode Border
    ├── UpgradesTitleBar        Frame
    │   │   AnchorPoint (0, 0) · Position (0, 0, 0, 0) · Size (1, 0, 0, 64)
    │   │   BackgroundColor3 (64, 156, 255)  [Blue] · BackgroundTransparency 0
    │   ├── UpgradesTitleBarCorner UICorner    CornerRadius (0, 20)
    │   ├── UpgradesTitle       TextLabel
    │   │       AnchorPoint (0, 0) · Position (0, 20, 0, 0) · Size (1, -80, 1, 0)
    │   │       Font FredokaOne · TextSize 28 · Text "📈 UPGRADES" · TextColor3 (255, 255, 255)
    │   │       TextXAlignment Left · TextYAlignment Center
    │   └── UpgradesCloseSlot   Frame          ← empty slot, CloseButtonPane parented here by code
    │           AnchorPoint (1, 0.5) · Position (1, -10, 0.5, 0) · Size (0, 44, 0, 44)
    │           BackgroundTransparency 1
    ├── UpgradesRowList         Frame
    │   │   AnchorPoint (0, 0) · Position (0, 20, 0, 80) · Size (1, -40, 0, 240)
    │   │   BackgroundTransparency 1
    │   └── UpgradesRowListLayout UIListLayout
    │           FillDirection Vertical · HorizontalAlignment Center
    │           VerticalAlignment Top · Padding (0, 12) · SortOrder LayoutOrder
    └── UpgradesMessage         TextLabel      ← result line; code sets Text/green-red color, clears after 2.5s
            AnchorPoint (0, 0) · Position (0, 20, 0, 332) · Size (1, -40, 0, 56)
            Font GothamBold · TextSize 18 · Text "" · TextColor3 (86, 196, 72)
            TextXAlignment Center · TextYAlignment Center · TextWrapped true
```

### ShopPaneTemplate  (`Assets/Gui/Hud`)

Used by `ShopPane` (`Instances`: `ShopPanel`, `ShopStroke`, `ShopTitleBar`,
`ShopTitle`, `ShopCloseSlot`, `ShopFeaturedSlot`, `ShopSectionLabel`,
`ShopProductRow`, `ShopMessage`). `CloseButtonPane` goes into `ShopCloseSlot`,
the featured pass `ShopItemButtonPane` fills `ShopFeaturedSlot` (Size 1,1
scale), product `ShopItemButtonPane` clones (150×150) go into
`ShopProductRow` - all at runtime.

```
ShopPaneTemplate                Frame          ← invisible centered anchor; panel pops inside it
│   AnchorPoint (0.5, 0.5) · Position (0.5, 0, 0.5, 0) · Size (0, 520, 0, 460)
│   BackgroundTransparency 1
└── ShopPanel                   Frame          ← code scale-pops this via spring
    │   AnchorPoint (0.5, 0.5) · Position (0.5, 0, 0.5, 0) · Size (1, 0, 1, 0)
    │   BackgroundColor3 (247, 243, 234)  [Panel] · BackgroundTransparency 0
    ├── ShopPanelCorner         UICorner       CornerRadius (0, 20)
    ├── ShopStroke              UIStroke       Color (34, 44, 72) · Thickness 4 · ApplyStrokeMode Border
    ├── ShopTitleBar            Frame
    │   │   AnchorPoint (0, 0) · Position (0, 0, 0, 0) · Size (1, 0, 0, 64)
    │   │   BackgroundColor3 (255, 146, 52)  [Orange] · BackgroundTransparency 0
    │   ├── ShopTitleBarCorner  UICorner       CornerRadius (0, 20)
    │   ├── ShopTitle           TextLabel
    │   │       AnchorPoint (0, 0) · Position (0, 20, 0, 0) · Size (1, -80, 1, 0)
    │   │       Font FredokaOne · TextSize 28 · Text "🛒 SHOP" · TextColor3 (255, 255, 255)
    │   │       TextXAlignment Left · TextYAlignment Center
    │   └── ShopCloseSlot       Frame          ← empty slot, CloseButtonPane parented here by code
    │           AnchorPoint (1, 0.5) · Position (1, -10, 0.5, 0) · Size (0, 44, 0, 44)
    │           BackgroundTransparency 1
    ├── ShopFeaturedSlot        Frame          ← empty slot, featured pass button fills it (Size 1,1 scale)
    │       AnchorPoint (0, 0) · Position (0, 20, 0, 80) · Size (1, -40, 0, 96)
    │       BackgroundTransparency 1
    ├── ShopSectionLabel        TextLabel
    │       AnchorPoint (0, 0) · Position (0, 20, 0, 188) · Size (1, -40, 0, 24)
    │       Font GothamBlack · TextSize 16 · Text "CASH PACKS" · TextColor3 (44, 56, 86)
    │       TextXAlignment Left · TextYAlignment Center
    ├── ShopProductRow          Frame
    │   │   AnchorPoint (0, 0) · Position (0, 20, 0, 220) · Size (1, -40, 0, 150)
    │   │   BackgroundTransparency 1
    │   └── ShopProductRowLayout UIListLayout
    │           FillDirection Horizontal · HorizontalAlignment Center
    │           VerticalAlignment Center · Padding (0, 12) · SortOrder LayoutOrder
    └── ShopMessage             TextLabel      ← result line; code sets Text/green-red color, clears after 2.5s
            AnchorPoint (0, 0) · Position (0, 20, 0, 384) · Size (1, -40, 0, 56)
            Font GothamBold · TextSize 18 · Text "" · TextColor3 (86, 196, 72)
            TextXAlignment Center · TextYAlignment Center · TextWrapped true
```

### ToastPaneTemplate  (`Assets/Gui/Hud`)

Used by `ToastPane` (`Instances`: `ToastLabel`, `ToastStroke`). Code drives
`ToastLabel.Position` upward from (0.5, 0, 0.5, 0) while it fades - keep its
AnchorPoint (0.5, 0.5).

```
ToastPaneTemplate               Frame          ← non-interactive, centered upper-middle of screen
│   AnchorPoint (0.5, 0.5) · Position (0.5, 0, 0.35, 0) · Size (0, 600, 0, 80)
│   BackgroundTransparency 1
└── ToastLabel                  TextLabel
    │   AnchorPoint (0.5, 0.5) · Position (0.5, 0, 0.5, 0) · Size (1, 0, 0, 36)
    │   Font FredokaOne · TextSize 26 · Text "" · TextColor3 (255, 255, 255)
    │   TextXAlignment Center · TextYAlignment Center
    └── ToastStroke             UIStroke       Color (34, 44, 72) · Thickness 3 · ApplyStrokeMode Contextual
```

---

## Cross-check: `Instances` map → template name coverage

| Pane | Instances keys → template names |
|---|---|
| StatPillPane | PillDesign, PillStroke, PillIcon, PillText, PillFillTrack, PillFill |
| SideButtonPane | SideDesign, SideStroke, SideIcon, SideTitle, SideCost |
| CloseButtonPane | CloseDesign, CloseStroke, CloseIcon |
| BuyButtonPane | BuyDesign, BuyStroke, BuyLabel |
| UpgradeRowPane | RowIconBadge, RowIcon, RowName, RowLevel, RowProgressTrack, RowProgressFill, RowBuySlot |
| ShopItemButtonPane | ShopItemDesign, ShopItemStroke, ShopItemTitle, ShopItemSubtitle |
| TopHudPane | PillRow |
| HudSideButtonsPane | SideButtonList |
| UpgradesPane | UpgradesPanel, UpgradesStroke, UpgradesTitleBar, UpgradesTitle, UpgradesCloseSlot, UpgradesRowList, UpgradesMessage |
| ShopPane | ShopPanel, ShopStroke, ShopTitleBar, ShopTitle, ShopCloseSlot, ShopFeaturedSlot, ShopSectionLabel, ShopProductRow, ShopMessage |
| ToastPane | ToastLabel, ToastStroke |

Every listed name appears exactly once in its template tree above.
