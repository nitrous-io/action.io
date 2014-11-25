image: 
	@docker build -t nitrousio/actionio-rails .
.PHONY: image
	
ci-test: image
	@docker run nitrousio/actionio-rails /home/app_runner/script/docker_test
.PHONY: ci-test
