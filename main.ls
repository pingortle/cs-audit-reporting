require! {
  \./generate-email
  \./fetch-mrn-tables
  Mustache
  prompt
  fs
  'prelude-ls': { map, filter }
  'dank-csv': csv-parse
}

csv = fs.read-file-sync process.argv[2] .to-string!
  |> csv-parse
  |> filter (.MerchantReferenceNumber)

email-data = generate-email(
  fs.read-file-sync process.argv[3] |> JSON.parse,
  csv
)

email-template = fs.read-file-sync \./email.mustache .to-string!

prompt.start!

(err, credentials) <- prompt.get [
  { name: \organizationId required: yes }
  { name: \username required: yes }
  {name: \password hidden: yes }
]
do
  (err, tables) <- fetch-mrn-tables(
    (csv |> map (.MerchantReferenceNumber)),
    credentials,
    proxy: "http://127.0.0.1:8888" strictSSL: no
  )
  email-data.mrn-tables = tables
  fs.write-file-sync(
    "tmp/email-#{current-date = Date.now!}.html"
    Mustache.render(email-template, email-data)
  )
