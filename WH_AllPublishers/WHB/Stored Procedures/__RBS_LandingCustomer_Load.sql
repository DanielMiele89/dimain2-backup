
CREATE PROC [WHB].[__RBS_LandingCustomer_Load]
AS
INSERT INTO [Inbound].[RBS_Customer]([FanID], [ClubID], [SourceUID], [CompositeID], [AccountType], [Title], [City], [County], [Region], [PostalSector], [PostCodeDistrict], [PostArea], [Gender], [AgeCurrent], [AgeCurrentBandText], [MarketableByEmail], [MarketableByDirectMail], [CurrentlyActive], [RegistrationDate], [DeactivatedDate])
SELECT TOP (1000) 
		[FanID]
	  ,[ClubID]
      ,[SourceUID]
      ,[CompositeID]
	  ,NULL AS AccountType
      ,[Title]
      ,[City]
      ,[County]
      ,[Region]
      ,[PostalSector]
      ,[PostCodeDistrict]
      ,[PostArea]
      ,[Gender]
      ,[AgeCurrent]
      ,[AgeCurrentBandText]
      ,[MarketableByEmail]
      ,[MarketableByDirectMail]
      ,[CurrentlyActive]
      ,[ActivatedDate]
      ,[DeactivatedDate]
  FROM [Warehouse].[Relational].[Customer]
