CREATE VIEW [dbo].[CBP_Credit_TSYSIDToCINMapping]
AS
SELECT [IssuerID]
      ,[TSYSCIN]
      ,[CIN]
      ,[DateCreated]
      ,[DateModified]
      ,[CINtoCINmerger]
  FROM SLC_Snapshot.[dbo].[CBP_Credit_TSYSIDToCINMapping]

