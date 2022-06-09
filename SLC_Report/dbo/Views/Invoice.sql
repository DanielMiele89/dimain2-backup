﻿CREATE VIEW [dbo].[Invoice]
AS
SELECT [ID]
      ,[InvoiceNumber]
      ,[RangeDateFrom]
      ,[RangeDateTo]
      ,[PartnerID]
      ,[Paid]
      ,[PreviousTransIncluded]
      ,[InvoiceTitle]
      ,[InvoiceDescription]
      ,[InvoiceType]
      ,[PartnerTitle]
      ,[PartnerName]
      ,[InvoiceBankAccountId]
      ,[InvoiceDate]
      ,[PaymentDue]
      ,[AdjustedVat]
      ,[PONumber]
FROM SLC_Snapshot.dbo.[Invoice]