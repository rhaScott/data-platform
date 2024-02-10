## Auth
gcloud auth application-default login

## GitHub Workflows: Workload Identity Pool & Provider Setup 
# Create Github Pool
gcloud iam workload-identity-pools create "github" \
  --project="${PROJECT_ID}" \
  --location="global" \
  --display-name="GitHub Actions Pool"

# Get pool ID
gcloud iam workload-identity-pools describe "github" \
  --project="${PROJECT_ID}" \
  --location="global" \
  --format="value(name)"

# Create "data-platform" Provider
gcloud iam workload-identity-pools providers create-oidc "data-platform" \
  --project="${PROJECT_ID}" \
  --location="global" \
  --workload-identity-pool="github" \
  --display-name="My GitHub repo Provider" \
  --attribute-mapping="google.subject=assertion.sub,attribute.actor=assertion.actor,attribute.repository=assertion.repository,attribute.repository_owner=assertion.repository_owner" \
  --attribute-condition="assertion.repository_owner == '${GITHUB_ORG}'" \
  --issuer-uri="https://token.actions.githubusercontent.com"

# Get pool provider ID
gcloud iam workload-identity-pools providers describe "data-platform" \
  --project="${PROJECT_ID}" \
  --location="global" \
  --workload-identity-pool="github" \
  --format="value(name)"

## Secret Manager Setup
# Enable Secret Manager
gcloud services enable secretmanager.googleapis.com --project="${PROJECT_ID}"

# Give provider roles
    #REPO format = "org/repo"
gcloud secrets add-iam-policy-binding "my-secret" \
  --project="${PROJECT_ID}" \
  --role="roles/secretmanager.secretAccessor" \
  --member="principalSet://iam.googleapis.com/${WORKLOAD_IDENTITY_POOL_PROVIDER_ID}/attribute.repository/${REPO}"

# Add BigQuery roles
  #--role="roles/bigquery.dataEditor" \
  #--role="roles/bigquery.dataViewer" \
  #--role="roles/bigquery.jobUser" \
  #--role="roles/bigquery.metadataViewer" \
