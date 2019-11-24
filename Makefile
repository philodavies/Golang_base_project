##### =====> Internals <===== #####

# Data used for the packaging of the code
VERSION          := $(shell git describe --tags --always --dirty="-dev")
DATE             := $(shell date -u '+%Y-%m-%d-%H%M UTC')
VERSION_FLAGS    := -ldflags='-X "main.Version=$(VERSION)" -X "main.BuildTime=$(DATE)"'
ARCH             := GOOS=linux GOARCH=amd64

# Used by various triggers (List of directories to check with tools)
SRCS := $(shell go list ./cmd/... )
SRC_DIRS := #fill this with the various package directories for the project (cmd, pb, etc...)

##### =====> Main targets <===== #####


##### =====> Utility targets <===== #####

.PHONY: clean
clean:
	rm -f coverage.cov coverage.html

# The comprehensive test does not include go test
# This is simply a target to test for all other possible mistakes
.PHONY: comprehensive-test
comprehensive-test:
	@make errcheck
	@make fmt
	@make ineffassign
	@make lint
	@make misspell
	@make staticcheck
	@make unconvert
	@make unparam
	@make vet

.PHONY: errcheck
errcheck:
	@go get github.com/kisielk/errcheck
	@echo ""
	@echo "=====> Checking code for unchecked errors: <====="
	@echo ""
	@errcheck $(SRCS)

.PHONY: fmt
fmt:
	@echo ""
	@echo "=====> Checking code is formatted: <====="
	@echo ""
	@gofmt -s -l -d -e $(SRC_DIRS)

.PHONY: ineffassign
ineffassign:
	@go get github.com/gordonklaus/ineffassign
	@echo ""
	@echo "=====> Checking code for ineffectual assignments: <====="
	@echo ""
	@find $(SRC_DIRS) -name '*.go' | xargs ineffassign

.PHONY: lint
lint:
	@go get golang.org/x/lint/golint
	@echo ""
	@echo "=====> Checking code is linted: <====="
	@echo ""
	@golint $(shell go list ./... | grep -v /vendor/)

.PHONY: misspell
misspell:
	@go get github.com/client9/misspell/cmd/misspell
	@echo ""
	@echo "=====> Checking code for misspellings: <====="
	@echo ""
	@misspell \
		cmd docker exports locations stream test_files \
		*.md *.go

.PHONY: staticcheck
staticcheck:
	@go get honnef.co/go/tools/cmd/staticcheck
	@echo ""
	@echo "=====> Checking code for issues with staticcheck: <====="
	@echo ""
	@staticcheck $(SRCS)

.PHONY: test
test:
	@echo ""
	@echo "=====> Running tests: <====="
	@echo ""
	@go test -race -coverprofile=coverage.cov -covermode=atomic ./...
	@echo ""
	@echo "=====> Total test coverage: <====="
	@echo ""
	@go tool cover -func coverage.cov

test-html: test
	@go tool cover -html coverage.cov -o coverage.html

.PHONY: unconvert
unconvert:
	@go get github.com/mdempsky/unconvert
	@echo ""
	@echo "=====> Checking code for unnecessary type conversions: <====="
	@echo ""
	@unconvert -v $(SRCS)

.PHONY: unparam
unparam:
	@go get mvdan.cc/unparam
	@echo ""
	@echo "=====> Checking code for unused function parameters and results: <====="
	@echo ""
	@unparam ./...

.PHONY: vet
vet:
	@echo ""
	@echo "=====> Checking code for suspicious constructs with vet: <====="
	@echo ""
	@go vet ./...
