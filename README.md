# Tool for Remote Pair/Mob Programming
This is a port of the basics of [https://github.com/remotemobprogramming/mob](https://github.com/remotemobprogramming/mob).


Swift handover for remote mobs using git.
`mob` is a CLI tool written in PowerShell.
It keeps your master branch clean and creates WIP commits on `mob-session` branch.

## How to use it?
Copy `MobProgramming.*` scripts into your git repo as `mob.*` for simplicity.
```bash
# quinn begins the mob session as typist
quinn$ mob start
# WORK
# When it's time to switch control
quinn$ mob next
# peggy takes over as the second typist
peggy$ mob start
# WORK
# When it's time to switch control
peggy$ mob next
laura$ mob start
# WORK
# When work is done
laura$ mob done
laura$ git commit --message "describe what the mob session was all about"
```

## How does it work?

- `mob start` creates branch `mob-session` and pulls from `origin/mob-session`
- `mob next` pushes all changes to `origin/mob-session`in a `WIP in Mob Sessions` commit
- `mob done` squashes all changes in `mob-session` into staging of `master` and removes `mob-session` and `origin/mob-session` 
- `mob status` display the mob session status and all the created WIP commits
- `mob reset` deletes `mob-session` and `origin/mob-session`

## How does it really work?

It's a `TODO` to display git commands and messages.


## How to contribute

Create a pull request.