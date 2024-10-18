FROM public.ecr.aws/lambda/python:3.12

COPY requirements.txt  .
RUN pip install --upgrade pip && pip3 install -r requirements.txt --target "${LAMBDA_TASK_ROOT}"
COPY src ${LAMBDA_TASK_ROOT}

# Set the CMD to your handler (could also be done as a parameter override outside of the Dockerfile)
CMD [ "main.handler" ]
