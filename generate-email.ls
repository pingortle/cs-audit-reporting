require! {
  'prelude-ls': { concat-map, map, keys, flatten, fold, filter, sort-by, group-by, Obj }
}

generate-email = (settings, data) ->
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

module.exports = generate-email
