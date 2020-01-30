# Bootstrap (pull) the build harness

# GITHUB_USER containing '@' char must be escaped with '%40'
GITHUB_USER := $(shell echo $(GITHUB_USER) | sed 's/@/%40/g')
GITHUB_TOKEN ?=

-include $(shell curl -so .build-harness-bootstrap -H "Authorization: token $(GITHUB_TOKEN)" -H "Accept: application/vnd.github.v3.raw" "https://raw.github.ibm.com/ICP-DevOps/mvp-build-harness-extensions/master/templates/Makefile.build-harness-bootstrap"; echo .build-harness-bootstrap)