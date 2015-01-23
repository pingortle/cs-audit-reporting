require! {
  fs
  'dank-csv': csv-parse
  Mustache: stache
  'prelude-ls': { concat-map, map, keys, flatten, fold, filter, sort-by, group-by, Obj }
}

email-template = fs.read-file-sync 'email.mustache' .to-string!
settings = fs.read-file-sync 'settings.json' |> JSON.parse
data = fs.read-file-sync (process.argv[2] or 'dailyaudit.csv') .to-string!
  |> csv-parse
  |> filter (.MerchantReferenceNumber)

locations = data
  |> group-by (.CyberSourceMerchantID)
  |> Obj.map map (.MerchantReferenceNumber)

response =
  to: locations
    |> keys
    |> concat-map (key) -> settings.locations[key]?.emails or []
  cc: settings.always-copy
  locations: locations
    |> keys
    |> map (key) ->
      name: settings.locations[key]?.display-name or key
      customers: map (mrn) -> { mrn }, locations[key]
  body-text: if data.length > 1 then settings.multiple-MRN-text else settings.single-MRN-text

console.log response
fs.write-file-sync "tmp/email-#{current-date = Date.now!}.html" stache.render(email-template, response)
fs.write-file-sync "tmp/data-#{current-date}.json" JSON.stringify(response, null, 2)
