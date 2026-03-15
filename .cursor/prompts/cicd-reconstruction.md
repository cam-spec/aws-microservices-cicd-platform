Reconstruct CI/CD pipeline artifacts for this AWS microservices project.

The repository previously used AWS CodePipeline, CodeBuild, and CodeDeploy to deploy containerized services to AWS ECS.

You must reconstruct the following files:

buildspec.yml
appspec.yaml

buildspec.yml must:

- install dependencies
- build Docker images
- tag images
- prepare deployment artifacts

appspec.yaml must:

- reference ECS task definitions
- define container names
- define container ports

These artifacts should represent a realistic AWS CI/CD workflow for ECS deployments.