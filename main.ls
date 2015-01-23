require! {
  \./generate-email
  \./fetch-mrn-tables
  \./utility
  \Mustache
  \fs
  'prelude-ls': { map }
}

csv = fs.read-file-sync process.argv[2] .to-string! |> utility.audit-report-to-array

email-data = generate-email(
  fs.read-file-sync process.argv[3] |> JSON.parse,
  csv)

email-template = fs.read-file-sync \./email.mustache .to-string!

do
  (err, tables) <- fetch-mrn-tables (csv |> map (.MerchantReferenceNumber))
  email-data.mrn-tables = tables
  fs.write-file-sync(
    "tmp/email-#{current-date = Date.now!}.html"
    Mustache.render(email-template, email-data))
