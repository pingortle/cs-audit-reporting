require! {
  async
  request
  jsdom
  'prelude-ls': { at, filter, first, keys, find, map }
}

mrnToTable = (rq, mrn, cb) -->
  (error, response, body) <- rq 'https://ebc.cybersource.com/ebc/transactionsearch/TransactionSearchLoad.do?regular=true'
  (errors, window) <- jsdom.env body, ['http://code.jquery.com/jquery.js']
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
      csrfToken: window.$('input[name="csrfToken"]').val!
    }
  }
  (jsErrors, window) <- jsdom.env body, ['http://code.jquery.com/jquery.js']
  cb error, window.$('table table table:nth-of-type(3)').wrap('<div />').parent!.html!

login = (rq, jar, { organizationId, username, password }, cb) ->
  (error, response, body) <- rq 'https://ebc.cybersource.com/ebc/login/Login.do'
  rq.post 'https://ebc.cybersource.com/ebc/login/LoginProcess.do', {
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

fetch-mrn-tables = (mrns, credentials, callback) ->
  jar = request.jar!
  rq = request.defaults {
    jar
    proxy: "http://127.0.0.1:8888"
    strictSSL: no
    followAllRedirects: yes
  }

  (e, r) <- login rq, jar, credentials
  (error, results) <- async.map mrns, mrnToTable rq
  callback error, results

module.exports = fetch-mrn-tables
