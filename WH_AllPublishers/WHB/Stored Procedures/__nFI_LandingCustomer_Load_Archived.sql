

CREATE PROC [WHB].[__nFI_LandingCustomer_Load_Archived]
AS
INSERT INTO [WH_AllPublishers].[Inbound].[nFI_Customer] (
[FanID]
      ,[ClubID]
      ,[CompositeID]
      ,[SourceUID]
      ,[Region]
      ,[PostalSector]
      ,[Gender]
      ,[AgeCurrent]
      ,[RegistrationDate])
SELECT 
	[FanID]
      ,[ClubID]
      ,[CompositeID]
      ,[SourceUID]
      ,[Region]
      ,[PostalSector]
      ,[Gender]
      ,[AgeCurrent]
      ,[RegistrationDate]
FROM [nFI].[Relational].[Customer]
