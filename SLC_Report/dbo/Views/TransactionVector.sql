CREATE VIEW [dbo].[TransactionVector]
AS
SELECT 
[ID]
      ,[Name]
      ,[Type]
      ,[Abbreviation]
      ,[FeedConsumer]
  FROM [SLC_Snapshot].[dbo].[TransactionVector]