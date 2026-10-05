# Adding a component

## Before you build

Check the [components list](../components/index.md) and the catalogue.
Extending an existing widget with an **optional** parameter is better than a new
widget. A component belongs in `mano_ui` when **two or more screens** need it;
otherwise keep it private to the feature.

## Rules

- **Inputs are strings, booleans, numbers, callbacks and `Widget` slots.** Never a
  domain type. `mano_ui` can't import `mano_domain`, and `dart analyze` fails if
  you try.
- **Tokens only:** `ManoColors`, `ManoSpacing`, `ManoRadius`, `ManoMotion`, and
  text from `Theme.of(context).textTheme`.
- **No images in `mano_ui`.** Take a `Widget` slot instead.
- **Must not overflow at 360 dp or at 2× text.** Prices shrink rather than
  truncate.
- **Accessible.** Aim for 48 dp tappable targets; icons that carry meaning
  have semantics labels.

## Steps

1. **Test first:** `packages/mano_ui/test/widgets/mano_<name>_test.dart`.
2. **Widget:** `packages/mano_ui/lib/src/widgets/mano_<name>.dart`, plus one export
   line in `lib/mano_ui.dart`.
3. **Catalogue:** add a use case in the matching `widgetbook/lib/src/<category>.dart`,
   with knobs for the props a designer would want to try. The Widgetbook test
   fails until every exported widget has one.
4. **Docs:** add a row to [Components](../components/index.md).
