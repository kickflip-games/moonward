# Complete the reference import

Download the **Moonward reference ZIP** from the ChatGPT response. Extract it locally, then use a clone of `kickflip-games/moonward`.

This branch contains the Markdown index and catalog, **but the 19 original PNG image files must still be imported**.

```bash
git fetch origin
git switch references/moonward-design-library
# Replace /path/to/... with the location of the extracted archive
cp -R /path/to/moonward_reference_import/references/. references/
git add references/
git commit -m "docs: import Moonward greybox and art reference PNGs"
git push origin references/moonward-design-library
```

Afterward verify [reference index](README.md) and [image manifest](manifest.json) and merge the branch. Importing this does not modify active Godot scene files or game assets.
