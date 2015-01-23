require! { fs, 'dank-csv': csv-parse, 'prelude-ls': { filter }  }

module.exports =
  audit-report-to-array: (csvData) ->
    csvData
      |> csv-parse
      |> filter (.MerchantReferenceNumber)
