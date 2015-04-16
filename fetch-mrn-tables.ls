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

mrnToTable = (rq, mrn, cb) -->
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

pastWeekToTable = (rq, customerId, cb) -->
  (error, response, body) <- rq 'https://ebc.cybersource.com/ebc/transactionsearch/TransactionSearchLoad.do?regular=true'
  (error, response, body) <- rq.post 'https://ebc.cybersource.com/ebc/transactionsearch/TransactionSearchExecute.do', {
    form: {
      validForm: \true
      searchType: "Field Search"
      searchField: \customer_id
      searchValue: customerId
      presetDate: \weektodate
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

transactionToTables = (rq, transaction, cb) -->
  funcs =
    mrn: (cb) -> mrnToTable rq, transaction.mrn, cb
    pastWeek: (cb) -> pastWeekToTable rq, transaction.customerId, cb

  async.parallel funcs, cb



login = (rq, jar, { organizationId, username, password }, cb) ->
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
  rq = request.defaults {
    jar
    followAllRedirects: yes
  } <<< (opts or {})

  (e, r) <- login rq, jar, credentials
  (error, results) <- async.map transactions, transactionToTables rq
  callback error, results

module.exports = fetch-mrn-tables
