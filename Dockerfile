# based on: https://github.com/aws/aws-lambda-python-runtime-interface-client
# Define custom function directory
ARG FUNCTION_DIR="/function"
FROM public.ecr.aws/docker/library/python:3.11-slim-bullseye as build-image

# Include global arg in this stage of the build
ARG FUNCTION_DIR
ARG APP_NAME

# Install aws-lambda-cpp build dependencies
RUN apt-get update --fix-missing \
  && apt-get -y install --no-install-recommends \
    g++ \
    make \
    cmake \
    zip \
    unzip \
    curl \
    libcurl4-openssl-dev \
  && apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Add Lambda local emulator
RUN curl https://github.com/aws/aws-lambda-runtime-interface-emulator/releases/latest/download/aws-lambda-rie \
      -Lo /usr/local/bin/aws-lambda-rie && \
      chmod +x /usr/local/bin/aws-lambda-rie

# Install the function's dependencies
WORKDIR ${FUNCTION_DIR} 
# Install requirements for Lambda function + Lambda Python runtime support
COPY lambdas/${APP_NAME}/requirements.txt .
RUN pip install \
    --target . \
    -r ${FUNCTION_DIR}/requirements.txt \
    awslambdaric
# Copy Lambda function code
COPY lambdas/${APP_NAME}/src/${APP_NAME}/* ./app/


FROM public.ecr.aws/docker/library/python:3.11-slim-bullseye

# Include global arg in this stage of the build
ARG FUNCTION_DIR
# Set working directory to function root directory
WORKDIR ${FUNCTION_DIR}

# Copy in the built dependencies
COPY --from=build-image ${FUNCTION_DIR} ${FUNCTION_DIR}
COPY --from=build-image /usr/local/bin/aws-lambda-rie /usr/local/bin/aws-lambda-rie

ENTRYPOINT [ "/usr/local/bin/aws-lambda-rie", "/usr/local/bin/python", "-m", "awslambdaric"]
CMD [ "app.main.handler" ]