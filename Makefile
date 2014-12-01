image: 
	@docker build -t nitrousio/actionio-rails .
.PHONY: image
	
ci-test: image
	@./script/ci_test
.PHONY: ci-test
