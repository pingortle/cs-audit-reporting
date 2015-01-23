require! {
  fs
  async
  request
  jsdom
  prompt
  'dank-csv': csv-parse
  'prelude-ls': { at, filter, first, keys, find, map }
}

jar = request.jar()
request = request.defaults {
  jar
  /*proxy: "http://127.0.0.1:8888"*/
  strictSSL: no
  followAllRedirects: yes
}

mrnToTable = (mrn, cb) ->
  (error, response, body) <- request 'https://ebc.cybersource.com/ebc/transactionsearch/TransactionSearchLoad.do?regular=true'
  (errors, window) <- jsdom.env body, ['http://code.jquery.com/jquery.js']
  (error, response, body) <- request.post 'https://ebc.cybersource.com/ebc/transactionsearch/TransactionSearchExecute.do', {
    form: {
      validForm: \true
      searchType: "Field Search"
      searchField: \merchant_ref_number
      searchValue: mrn
      presetDate: \lastsixmonths
      searchTransactions: \50
      sortOrder: \DESC
      merchantId: \all
      csrfToken: window.$('input[name="csrfToken"]').val!
    }
  }
  (jsErrors, window) <- jsdom.env body, ['http://code.jquery.com/jquery.js']
  cb error, window.$('table table table:nth-of-type(3)').wrap('<div />').parent!.html!

login = (organizationId, username, password, cb) ->
  (error, response, body) <- request 'https://ebc.cybersource.com/ebc/login/Login.do'
  request.post 'https://ebc.cybersource.com/ebc/login/LoginProcess.do', {
    form: {
      loginToken: jar.getCookies("https://ebc.cybersource.com/ebc/login/LoginProcess.do")
      |> find (.key == "loginToken")
      |> (.value)
      requestFromPartner: ""
      organizationId
      username
      password
      alreadyVisited: \true
    }
  },
  cb

mrns = fs.read-file-sync process.argv[2] .to-string!
  |> csv-parse
  |> filter (.MerchantReferenceNumber)
  |> map (.MerchantReferenceNumber)

prompt.start!

(e, r) <- prompt.get [{ name: \organizationId required: yes } { name: \username required: yes } {name: \password hidden: yes }]
(e, r) <- login r.organizationId, r.username, r.password
(error, results) <- async.map mrns, mrnToTable
fs.write-file-sync 'results.html' results
