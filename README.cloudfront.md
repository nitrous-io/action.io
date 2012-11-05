= How it's done

1. Download the cfcurl.pl file from here: http://aws.amazon.com/code/1878
2. Create a file called ~/.aws-secrets and fill in your AWS credentials
   with this format:

```
%awsSecretAccessKeys = (
  # PPF on AWS
  'ppf' => {
    id => 'your aws key',
    key => 'your aws secret',
  },
);

```

3. If you're running on Ubuntu 12.04, you'll probably need to install
   the package ```libdigest-hmac-perl``` by running ```sudo apt-get
   install libdigest-hmac-perl```

4. Create a Cloudfront distribution with an XML file similar to
   ```cloudfront-production.xml``` and ```cloudfront-staging.xml```

5. Replace the host and the description with the domain that you want
   the cloufront distribution to redirect all requests to.
   (```cloudfront-production.xml``` points to www.action.io and
   ```cloudfront-staging.xml``` points to staging.action.io). Remember
   to change the timestamp to the time at which you're creating the
   distribution - if the timestamp is not unique, creation of the
   distribution will fail.

6. Run this command: ```perl cfcurl.pl --keyname ppf -- -X POST -H "Content-Type: text/xml;charset=utf-8" --upload-file cloudfront-staging.xml https://cloudfront.amazonaws.com/2010-11-01/distribution```
