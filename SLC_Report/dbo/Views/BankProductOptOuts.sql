/****** Script for SelectTopNRows command from SSMS  ******/
  CREATE VIEW [dbo].[BankProductOptOuts]
AS
SELECT [FanID]
      ,[BankProductID]
      ,[OptOutDate]
      ,[OptBackInDate]
  FROM [SLC_Snapshot].[dbo].[BankProductOptOuts]



