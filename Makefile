EMACS ?= /usr/bin/emacs
BATCH = $(EMACS) --batch -Q --eval '(package-initialize)' -L .

.PHONY: test compile clean

compile:
	$(BATCH) --eval '(setq byte-compile-error-on-warn t)' -f batch-byte-compile omarchy-follow.el

test:
	$(BATCH) -l test/omarchy-follow-test.el -f ert-run-tests-batch-and-exit </dev/null

clean:
	rm -f *.elc test/*.elc
