# This provides simple shortcuts for daily works
# This should not be considered as a production Makefile

default: # default action
	@echo "Do nothing special"

push.all:# push all commits to remotes
	@git push github master
	@git push origin master
	@git push origin core
