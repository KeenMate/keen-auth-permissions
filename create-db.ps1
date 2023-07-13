$templateName = "keen_auth_sample"

$dbHost = "localhost"
$dbUser = "postgres"
$dbPassword = "Password3000!!"
$database = "keen_auth_sample"
$regenerateDbContext = $false

$psqlArguments = @(
  "-v",
  "ON_ERROR_STOP=1",
  "-h",
  "$dbHost",
  "-U",
  "$dbUser"
)

$env:PGPASSWORD = $dbPassword

$dropScript = ((Get-Content -path ./db/01-create-sample-db.sql) -replace $templateName, $database)
$createStructureScript = ((Get-Content -path ./db/02-create-basic-structure-sample-db.sql) -replace $templateName, $database)
$createScript = ((Get-Content -path ./db/03-create-script.sql) -replace $templateName, $database)

Write-Host "Running drop script"
$dropScript | & psql $psqlArguments "postgres"

if ( !$? ) {
  Write-Host "Drop script failed with error code $LASTEXITCODE"
  Return
}

Write-Host "Running create structure script"
$createStructureScript | & psql $psqlArguments "--single-transaction" $database

if ( !$? ) {
  Write-Host "Create structure script failed with error code $LASTEXITCODE"
  Return
}

Write-Host "Running create script"
$createScript | & psql $psqlArguments "--single-transaction" $database

if ( !$? ) {
  Write-Host "Create script failed with error code $LASTEXITCODE"
  Return
}

if ($regenerateDbContext) {
  Push-Location "../keen-auth-permissions-generator"
  mix eg.gen
  Pop-Location
}