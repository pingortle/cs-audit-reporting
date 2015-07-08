require! {
  \./generate-email
  \./fetch-mrn-tables
  \./sql-add-to-EBPP
  Mustache
  prefsink: prefs
  prompt
  fs
  'prelude-ls': { map, filter, fold }
  'dank-csv': csv-parse
  'child_process': { exec }
}

prefJar =  prefs.loadSync \cs-audit-reporting or prefs.create \cs-audit-reporting {
  proxy: "http://127.0.0.1:8888"
  username: ""
  organization-id: ""
  email-settings: ""
  generate-sql: ""
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
  *name: \generate-sql default: prefJar.get \generate-sql

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

if credentials.\generate-sql && credentials."generate-sql"[0].toLowerCase! is "y"
  fs.write-file-sync "tmp/proc-#{current-date}.sql", (sql-add-to-EBPP csv).join ""

exec "start email-#{current-date}.html" { cwd: \tmp env: process.env }
exec "explorer tmp"
