
CREATE VIEW [zion].[Member_LifeTimeValue] AS 
SELECT [FanID]
      ,[CPOSEarning]
      ,[DPOSEarning]
	  ,[DDEarning]
	  ,[OtherEarning]
	  ,[CurrentAnniversaryEarning]
      ,[PreviousAnniversaryEarning]
  FROM [SLC_Snapshot].zion.[Member_LifeTimeValue]
