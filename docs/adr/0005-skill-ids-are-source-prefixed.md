# Pack skill ids are source-prefixed and flat on disk

Two packs can both ship a folder named `review`. The catalog id is `source/leaf` (`pack-a/review`). The directory written for an agent is one level deep (`pack-a-review`) and `SKILL.md` frontmatter `name:` is rewritten to match. Nested `pack-a/review/` is invisible to harnesses that only scan immediate children; keeping the leaf `review` makes some harnesses silently shadow one of them.
