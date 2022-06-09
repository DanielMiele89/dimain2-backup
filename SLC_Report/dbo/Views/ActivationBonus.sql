

CREATE VIEW [dbo].[ActivationBonus]
AS
SELECT  [ID]
      ,[FanID]
      ,[ActivationBonusAmount]
      ,[StartDate]
      ,[EndDate]
      ,[Claimed]
  FROM SLC_Snapshot.[dbo].[ActivationBonus]

