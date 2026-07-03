# Skill: Git Worktrees for Parallel Sessions

## When this skill activates
Activates when the user wants to work on multiple branches simultaneously, or when
running Claude Code sessions in parallel on the same repo (Boris-style fleet).

## What worktrees do
A git worktree is a separate checked-out directory from the same repository.
Multiple directories, one `.git` store. Each can be on a different branch.
Changes in one worktree don't affect others — no stashing needed to switch context.

## Setup pattern

The convention is: `~/[repo-name]-[N]` where N is 1, 2, 3...

```bash
# Example: Main working directory (already exists)
~/<your-project>/        # branch: main or current feature

# Create parallel worktrees
git -C ~/<your-project> worktree add ~/<your-project>-2 -b feature/new-api
git -C ~/<your-project> worktree add ~/<your-project>-3 -b fix/some-bug
```

Each worktree gets its own `.claude/task-context.md` scoped to that branch.

## List and manage worktrees

```bash
git worktree list                      # see all active worktrees
git worktree remove ~/<project>-2      # clean up when branch merges
git worktree prune                     # remove stale worktree records
```

## Example worktree conventions

| Project | Main dir | Worktree pattern |
|---------|----------|-----------------|
| `<your-project>` | `~/<project>` | `~/<project>-2`, `~/<project>-3` |
| `<client-name>` | `~/[client]-1` | `~/[client]-2`, `~/[client]-3` |

## Rules

- Never create a worktree inside the main repo directory.
- Each worktree needs its own Claude Code session (separate terminal tab).
- Name branches before creating worktrees — the branch name is the context.
- When a branch merges: `git worktree remove` the directory, then `git branch -d`.
