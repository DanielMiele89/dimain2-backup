
CREATE VIEW [dbo].[BankAccountTransaction]
AS
SELECT  [ID]
      ,[BankAccountID]
      ,[Amount]
      ,[TransID]
      ,[TransDate]
      ,[Status]
      ,[Reported]
      ,[ExportFileID]
  FROM SLC_Snapshot.[dbo].[BankAccountTransaction]


