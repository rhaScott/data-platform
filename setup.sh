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

## Creating a service account to impersonate with the workload identity pool
gcloud iam service-accounts create data-platform \
  --description="Service account for mock data-platform" \
  --display-name="data-platform"

gcloud iam service-accounts list --filter="displayName:'data-platform'" --format='value(email)'

#Enable IAM credentials API
gcloud services enable iamcredentials.googleapis.com --project=336697166112

#Some permissions for the service account
gcloud projects add-iam-policy-binding data-platform-413021 \
  --member='serviceAccount:data-platform@data-platform-413021.iam.gserviceaccount.com' \
  --role='roles/bigquery.jobUser'

gcloud projects add-iam-policy-binding data-platform-413021 \
  --member='serviceAccount:data-platform@data-platform-413021.iam.gserviceaccount.com' \
  --role='roles/iam.serviceAccountTokenCreator'

gcloud projects add-iam-policy-binding data-platform-413021 \
  --member='serviceAccount:data-platform@data-platform-413021.iam.gserviceaccount.com' \
  --role='roles/iam.serviceAccountUser'

# This command is a little hazy, I ran it after things started working.
# Going into https://console.cloud.google.com/iam-admin/workload-identity-pools/pool/github and granting access with repository_owner also worked.
  gcloud iam service-accounts add-iam-policy-binding data-platform@data-platform-413021.iam.gserviceaccount.com \
    --role='roles/iam.workloadIdentityUser' \
    --member="principal://iam.googleapis.com/projects/336697166112/locations/global/workloadIdentityPools/github/subject/github"

gcloud projects add-iam-policy-binding data-platform-413021 \
  --member='serviceAccount:data-platform@data-platform-413021.iam.gserviceaccount.com' \
  --role='roles/storage.objectCreator'

gsutil mb -p data-platform-413021 -l EU gs://data-platform/


#creating a service account
gcloud iam service-accounts keys create ~/key.json --iam-account data-platform@data-platform-413021.iam.gserviceaccount.com

# Below here hasn't been run.
################################
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
