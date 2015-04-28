require! {
  async
  request
  cheerio: \$
  'prelude-ls': { at, filter, first, keys, find, map }
}

extractTableData = (body) ->
  tableMaybe = $ 'table table table:nth-of-type(3)' body
  if tableMaybe.length
    tableMaybe
  else
    $ '#transactionSearchDetailsMain' body

mrnToTable = (opts, mrn, cb) -->
  rq = request.defaults opts
  (error, response, body) <- rq 'https://ebc.cybersource.com/ebc/transactionsearch/TransactionSearchLoad.do?regular=true'
  (error, response, body) <- rq.post 'https://ebc.cybersource.com/ebc/transactionsearch/TransactionSearchExecute.do', {
    form: {
      validForm: \true
      searchType: "Field Search"
      searchField: \merchant_ref_number
      searchValue: mrn
      presetDate: \lastsixmonths
      searchTransactions: \50
      sortOrder: \DESC
      merchantId: \all
      csrfToken: ($ 'input[name="csrfToken"]' body).val!
    }
  }
  cb(
    error
    $ '<div />'
      |> (.append extractTableData body)
      |> (.html!)
  )

pastWeekToTable = (opts, customerId, cb) -->
  rq = request.defaults opts
  (error, response, body) <- rq 'https://ebc.cybersource.com/ebc/transactionsearch/TransactionSearchLoad.do?regular=true'
  (error, response, body) <- rq.post 'https://ebc.cybersource.com/ebc/transactionsearch/TransactionSearchExecute.do', {
    form: {
      validForm: \true
      searchType: "Field Search"
      searchField: \customer_id
      searchValue: customerId
      presetDate: \lastsixmonths
      searchTransactions: \100
      sortOrder: \DESC
      merchantId: \all
      csrfToken: ($ 'input[name="csrfToken"]' body).val!
    }
  }
  cb(
    error
    $ '<div />'
      |> (.append extractTableData body)
      |> (.html!)
  )

transactionToTables = (opts, transaction, cb) -->
  funcs =
    mrn: mrnToTable opts, transaction.mrn
    pastWeek: pastWeekToTable opts, transaction.customerId

  async.series funcs, cb

login = (opts, jar, { organizationId, username, password }, cb) ->
  rq = request.defaults opts
  (error, response, body) <- rq 'https://ebc.cybersource.com/ebc/login/Login.do'
  rq.post(
    'https://ebc.cybersource.com/ebc/login/LoginProcess.do'

    {
      form: {
        loginToken: jar.getCookies "https://ebc.cybersource.com/ebc/login/LoginProcess.do"
          |> find (.key == "loginToken")
          |> (.value)
        requestFromPartner: ""
        organizationId
        username
        password
        alreadyVisited: \true
      }
    }

    cb
  )

fetch-mrn-tables = (transactions, credentials, opts, callback) ->
  (callback = opts) and (opts = null) if not callback?

  jar = request.jar!
  opts = {
    jar
    followAllRedirects: yes
  } <<< (opts or {})

  (e, r) <- login opts, jar, credentials
  async.mapSeries transactions, (transactionToTables opts), callback

module.exports = fetch-mrn-tables
