# Writing these docs

This handbook is Markdown in `docs/`, built by [Zensical](https://zensical.org)
inside Docker, so the repo needs no Python. The component catalogue is a
[Widgetbook](https://widgetbook.io) app in `widgetbook/`, compiled to the web and
served at `/widgetbook/`.

```bash
tools/docs.sh serve     # build the catalogue, then preview at http://localhost:8000
tools/docs.sh build     # static site in site/ (catalogue included)
tools/docs.sh catalogue # only rebuild the Widgetbook into docs/widgetbook/
```

## Style

- **Short.** Tables over paragraphs; one idea per section.
- **Two readers.** Designers read Brand, Components and Product; developers read
  everything. Avoid code in the Brand section unless it names a token.
- **Link to the source of truth** (a file, a token, a widget) instead of
  repeating values that can drift.
- **New pages** go in the `nav` in `zensical.toml`.
