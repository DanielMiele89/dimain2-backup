﻿CREATE VIEW Relational.CustomerDetails

as 

SELECT [FanID]
	  ,[CompositeID]
      ,[Status]
      ,[Gender]
      ,[Title]
      ,[PostalSector]
      ,[PostCodeDistrict]
      ,[PostArea]
      ,[Region]
      ,[Unsubscribed]
      ,[Hardbounced]
      ,[EmailStructureValid]
      ,[ValidMobile]
      ,[Primacy]
      ,[IsJoint]
      ,[ControlGroupNumber]
      ,[ReportGroup]
      ,[TreatmentGroup]
      ,[LaunchGroup]
      ,[Activated]
      ,[ActivatedDate]
      ,[ActivatedOffline]
      ,[MarketableByEmail]
      ,[MarketableByDirectMail]
      ,[EmailNonOpener]
      ,[OriginalEmailPermission]
      ,[OriginalDMPermission]
      ,[EmailOriginallySupplied]
      ,[CurrentEmailPermission]
      ,[CurrentDMPermission]
      ,[AgeCurrent]
      ,[AgeCurrentBandNumber]
      ,[AgeCurrentBandText]
      ,[ClubID]
      ,[DeactivatedDate]
      ,[OptedOutDate]
      ,[CurrentlyActive]
      ,[POC_Customer]
      ,[Rainbow_Customer]
      ,[Registered]
  FROM [Warehouse].[Relational].[Customer]

