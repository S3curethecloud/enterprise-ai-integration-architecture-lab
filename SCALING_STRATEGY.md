
Scaling Strategy
Scaling Philosophy

The lab starts local-first but is designed to scale into a cloud-native enterprise AI integration platform.

Local-first means the system can run on a laptop using Docker Compose for fast demos and interviews.

Enterprise-grade means the system boundaries, interfaces, controls, and deployment paths are designed so the same architecture can be moved to production-grade cloud infrastructure.

Scale Dimensions
Dimension	Local Lab	Enterprise Scale
API Entry	FastAPI	API Gateway, ALB, APIM, Cloud Run ingress
Compute	Docker Compose	ECS, EKS, AKS, GKE, Cloud Run
Identity	Mock JWT	Entra ID, IAM Identity Center, Okta, Cloud Identity
AI Model	Local/mock provider	Bedrock, Azure OpenAI, Vertex AI
RAG Store	Local files/vector DB	OpenSearch, Aurora pgvector, Azure AI Search, AlloyDB
Policy	Local policy engine	OPA, Cedar, managed policy service
Audit	JSON files	S3, CloudWatch, Log Analytics, Cloud Logging
Secrets	.env	Secrets Manager, Key Vault, Secret Manager
Observability	Local logs	OpenTelemetry, Grafana, Cloud-native monitoring
Horizontal Scaling

The services should remain stateless where possible:

api-gateway
ai-gateway
rag-service
policy-engine
ticketing-adapter
cmdb-adapter

Stateful components should be externalized:

vector store
audit storage
ticket records
approval queue
policy repository
Model Scaling

The model layer must be abstracted so the platform can support:

AWS Bedrock
Azure OpenAI
Vertex AI
OpenAI API
local models
future internal models

The AI Gateway should route based on:

risk level
cost profile
latency requirements
data classification
model capability
provider availability
Enterprise Deployment Future

The cloud deployment should eventually include:

private networking
workload identity
service-to-service authorization
centralized logging
secrets management
least privilege IAM
policy-as-code
infrastructure-as-code
CI/CD validation
security tests
