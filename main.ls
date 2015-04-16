require! {
  \./generate-email
  \./fetch-mrn-tables
  Mustache
  prefsink: prefs
  prompt
  fs
  'prelude-ls': { map, filter, fold }
  'dank-csv': csv-parse
}

prefJar =  prefs.loadSync \cs-audit-reporting or prefs.create \cs-audit-reporting {
  proxy: "http://127.0.0.1:8888"
  username: ""
  organization-id: ""
  email-settings: ""
}

proxy = prefJar.get \proxy

csv = fs.read-file-sync process.argv[2] .to-string!
  |> csv-parse
  |> filter (.MerchantReferenceNumber)

email-data = generate-email(
  prefJar.get \email-settings |> fs.read-file-sync |> JSON.parse
  csv
)

email-template = fs.read-file-sync \./email.mustache .to-string!

promptOptions =
  *name: \proxy default: prefJar.get \proxy
  *name: \organizationId default: prefJar.get \organizationId
  *name: \username default: prefJar.get \username
  *name: \password required: yes hidden: yes

if prefJar.get \autopilot
  prompt.override = promptOptions
    |> filter (.default)
    |> fold ((a, b) -> a <<< "#{b.name}": b.default), {}

prompt.start!

(err, credentials) <- prompt.get promptOptions
(err, tables) <- fetch-mrn-tables(
  csv |> map (x) -> { mrn: x.MerchantReferenceNumber, customerId: x.Account } 
  credentials
  { proxy: (proxy or undefined), strictSSL: no }
)
fs.write-file-sync(
  "tmp/email-#{current-date = Date.now!}.html"
  Mustache.render email-template, email-data <<< mrn-tables: tables
)
