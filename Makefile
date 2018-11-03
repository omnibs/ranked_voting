# -*- mode: makefile-gmake -*-


#
# What's in a Makefile?
# ---------------------
#
# Rules like this:
#
#   target: [prerequisite] [...]
#       shell command
#       another shell \
#          command on multiple lines
#
# The target is the name of a file that can be built by those shell commands. If
# you run `make target` and the target is older than any of the prerequisite
# files, or doesn't exist, Make runs the shell commands. The prerequisites are
# also file names; Make will look for rules to build them too, recursively. If
# all of them are up to date, Make will say "`target' is up to date" and exit
# without running any commands.
#
# Some things that might trip you up at first:
#
# - Those shell commands MUST be indented by a proper tab character.
#
# - Each line of shell commands is $-expanded by Make BEFORE being passed to the
#   shell. Make expands $(NAME) and ${NAME} but $NAME would work like ${N}AME.
#
# - Each logical shell command is run in a separate shell. The example above
#   would result in something like the following:
#
#     $(SHELL) -c 'shell command' && $(SHELL) -c 'another shell command on ...'
#
#   This means that *shell* variables and functions are not passed from one
#   command to the next.
#
# - Execution stops at the first failure.
#
# If the symbols in this Makefile look weird, check here:
#
#   https://www.gnu.org/software/make/manual/html_node/Quick-Reference.html
#
# but for convenience here are a few that are more common:
#
#   $@     The file name of the target.
#   $<     The name of the first prerequisite.
#   $^     The names of all the prerequisites.
#   $(@D)  The directory part of $@.
#   $(@F)  The file-within-directory (`basename`) part of $@.
#   $$     A literal dollar sign. Useful when you really need to
#          reference a shell variable.
#


# Always use Bash. Make will default to `/bin/sh` otherwise. The one thing worse
# than `bash` is `sh`, or Bash's impersonation of `sh`. See bash(1), INVOCATION.
SHELL := bash


.PHONY: bootstrap
bootstrap:
ifeq ($(__noredink_env),)
	$(error It looks like direnv has not been set up yet)
else ifeq ($(__noredink_env),active)
	$(error The Nix environment is active; `make bootstrap-clean` and try again)
else ifeq ($(__noredink_env),inactive)
	@ # Capture the environment from outside Nix.
	direnv dump > .envrc.outside
	@ # Capture the environment from inside Nix.
	nix-shell --show-trace --run "direnv dump" > .envrc.inside
	@ # Diff the two to create a script that can apply only those changes
	@ # to the environment that are necessary to load Nix.
	script/direnv-diff-dump .envrc.outside .envrc.inside > .envrc.cache
	@ # Capture checksums for all dependencies so `.envrc` can detect if
	@ # something has changed. This is more reliable and less noisy than
	@ # comparing timestamps.
	/usr/bin/shasum --portable $(shell /usr/bin/sed '/^$$/d;/^#/d' .envrc.deps) > .envrc.sums
else
	$(error Not sure what to do when __noredink_env=$(__noredink_env))
endif


.PHONY: bootstrap-clean
bootstrap-clean:
	$(RM) .envrc.sums .envrc.cache .envrc.outside .envrc.inside


# End.
