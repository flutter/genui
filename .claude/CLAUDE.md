# Claude Code Context

Follow the guidelines in `docs/contributing/README.md`.

## Skills

Repository skills live in `.agent/skills/`, shared with the other agent tools
this repo supports. Claude Code only discovers skills under `.claude/skills/`,
so symlink the skills into it:

```bash
ln -s ../../.agent/skills/<name> .claude/skills/<name>
```
