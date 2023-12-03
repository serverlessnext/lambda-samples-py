
Python Lambda Samples
==========
This repository is dedicated to sharing AWS Lambda functions written in Python.
Feel free to use these for learning, exploration, prototyping or to quickstart your next billion dollar startup.

Each can be tested and deployed via the included Makefile. This depends on Docker for local test-run and on the AWS Cli (v2) for deployment.

The first example function is "s3_express". This function demonstrates how to connect to an S3 Express One Zone directory.


Prerequisites
-------------
- Mac or Linux -- on Windows, expecting it to work with WSL but have not tested this
- Docker or some equivalent container runtime
- Ability to run make
- AWS Cli v2
- an AWS account


Usage
-------------

.. code-block:: console

    make <lambda> <target> [<target> ...]

    targets:
        # local development with docker
        docker - build and run docker image for lambda
        docker_logs - tail logs for lambda
        docker_clean - cleanup docker for lambda
        # deploy to AWS Lambda
        zip - export lambda to zip file
        lambda_deploy_with_role - zip + create or update lambda and role
        lambda_delete_with_role - delete lambda and role
        lambda_invoke - invoke lambda
        lambda_patch - zip + patch existing lambda -- faster than deploy


Local Development
~~~~~~~~~~~~~~~~~~~~~~

    Note: AWS credentials from the environment are passed to the lambda

.. code-block:: console

    # build and run lambda in docker locally
    make s3_express docker

    # in another terminal, invoke lambda
    curl -XPOST "http://localhost:9000/2015-03-31/functions/function/invocations" -d '{}'

    # tail logs
    make s3_express docker_logs

    # chaining targets
    make s3_express docker docker_logs

    # cleanup docker
    make s3_express docker_clean


Deploy to AWS Lambda
~~~~~~~~~~~~~~~~~~~~~~

    Note: AWS CLI v2 is required for deployment. AWS CLI gets credentials from environment or ~/.aws/credentials.
    If you need to use a profile, set AWS_PROFILE=your_profile in environment.

.. code-block:: console

    # create zipfile to upload to AWS Lambda (x86/python3.11 runtime)
    make s3_express zip

    # zip + create or update lambda on AWS -- this also creates the execution role
    # with inline policy (permissions defined in file lambdas/<lambda>/role_policy.json)
    make s3_express lambda_deploy_with_role

    # delete lambda and role
    make s3_express lambda_delete_with_role

    # patch existing lambda (zip + upload)
    make s3_express lambda_patch

    # invoke lambda without payload
    make s3_express lambda_invoke

    # invoke lambda with payload
    make s3_express lambda_invoke payload='{"foo": "bar"}'


Lambdas
------------

S3 Express -- lambdas/s3_express
~~~~~~~~~~~~~~~~~~~~~~




Contributing
------------
Contributions that align with the spirit of this repository are always welcome.

License
-------
This repository is released under the MIT license. See LICENSE for more details.
