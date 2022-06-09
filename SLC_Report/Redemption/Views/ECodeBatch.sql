CREATE VIEW [Redemption].[ECodeBatch]
AS
SELECT  [ID]
      ,[LoadDate]
      ,[LoadedBy]
      ,[ExpiryDate]
      ,[RedeemID]
  FROM SLC_Snapshot.[Redemption].[ECodeBatch]