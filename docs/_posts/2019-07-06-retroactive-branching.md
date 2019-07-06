---
layout: single
title:  "Retroactive Branching in git"
published: true
---

Remember that time when I thought about that thing, but totally didn't do it?
Me too!

So, today I broke my blog. I completely vivisected it, causing all
manner of problems! I did this in order to try to get Perl 6 syntax
highlighting working (no dice: GitHub won't allow alternate syntax highlighters).

But in the process, I swapped out the style, highlighter and several other
things. In the end, it didn't work, so what should I do? I'd done the work on
master (hey, it's my tools/blog repo!) and so there was no branch to
keep those changes on if I reverted them.

## Warning

All of the steps below presume that you are working with branches that others don't
have checked out, currently. If the do, you are going to have to negotiate with
them. The easiest way to be sure that everything is fine is if they
sync their changes before your work, then remove their local copy and
re-clone.

## Reverting with reset

So you can always just reset a branch:

```bash
git checkout some-branch
git reset HEAD~
```

This removes the most recent commit from that branch.

The branch can then be pushed up to the origin repo, though `-f` will have
to be used because you're revising existing commits on the branch.

```bash
git push -f origin some-branch
```

But what if you wanted to keep that work?

## Branching retro-actively

A branch in git is just a label, and the difference between an
active branch and deleted commits is just whether or not there's
a label pointing to those commits. So, in my case with a broken
master, here's what I did:

First, I had a master that looked like this:

```bash
git log --graph --oneline
```

```
* c848265 (HEAD -> master, origin/master) Thanks, I hate it
* 3bba862 Broke more stuff
* 7e0fee1 Broke stuff
* 6f10c38 Minor fix
* a8c31a9 Lots of work
```

And then I did this:

```bash
git checkout master
git checkout -b abandoned-work-branch
git checkout master
# Now I have a new branch that's at the same
# commit as master... so far
git reset 6f10c38 # last working commit
git status
# Check to make sure we've reverted just what
# we intended to
git reset --hard
# That wipes out the modified files left by the
# first reset
git log --graph --oneline
```

Now I had something like this:

```
* c848265 (origin/master, abandoned-work-branch) Thanks, I hate it
* 3bba862 Broke more stuff
* 7e0fee1 Broke stuff
* 6f10c38 (HEAD -> master) Minor fix
* a8c31a9 Lots of work
```

All that's left is to push this new view of the world up:

```bash
git push origin abandoned-work-branch
git push -f origin master
```

Now, if anyone had copies of this repo checked out, they will have
to pull the new history and resolve any issues that arise.
Generally this is bad form for shared repos, but it's the fastest,
easiest way to go back in time.
