require! {
  mustache
  'prelude-ls': { map }
}

proc-template = '''
DECLARE	@return_value int
EXEC	@return_value = [dbo].[proc_CyberPaymentsUpdate]
@Site = {{Site}},
@Account = {{Account}},
@UserName = N'{{UserName}}',
@OrderNumber = N'{{MerchantReferenceNumber}}',
@MerchantID = N'{{CyberSourceMerchantID}}'
SELECT	'Return Value' = @return_value
GO

'''

mustache.render

create-sqlprocs = (customers) ->
  map ((c) -> mustache.render proc-template, c), customers

module.exports = create-sqlprocs
