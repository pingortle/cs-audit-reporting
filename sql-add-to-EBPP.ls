require! {
  mustache
  'prelude-ls': { map, concat }
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
  concat [
    (map ((c) -> mustache.render proc-template, c), customers), [
      '''

      DECLARE	@return_value int
      EXEC @return_value = [dbo].[proc_CyberPaymentsSendToEBPP]
      SELECT	'Return Value' = @return_value
      GO
      
      '''
    ]
  ]

module.exports = create-sqlprocs
