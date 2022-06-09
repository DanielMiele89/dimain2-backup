CREATE VIEW [zion].[Member_OneClickActivation] AS 
SELECT [FanID]
      ,[ActivationLinkGUID]
      ,[Date]
      ,[LinkActive]
  FROM SLC_Snapshot.[zion].[Member_OneClickActivation]