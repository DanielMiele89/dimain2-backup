﻿

CREATE PROC [WHB].[__Virgin_LandingCustomer_Load]
AS
INSERT INTO [WH_AllPublishers].[Inbound].[Virgin_Customer] ([FanID], [ClubID], [CompositeID], [SourceUID], [AccountType], [EmailStructureValid], [Title], [City], [County], [Region], [PostalSector], [PostCodeDistrict], [PostArea], [CAMEOCode], [Gender], [AgeCurrent], [AgeCurrentBandText], [CashbackPending], [CashbackAvailable], [CashbackLTV], [Unsubscribed], [Hardbounced], [MarketableByEmail], [MarketableByPush], [CurrentlyActive], [RegistrationDate], [DeactivatedDate])
SELECT 
	[FanID]
	,[ClubID]
	,[CompositeID]
	,[SourceUID]
	,[AccountType]
	,[EmailStructureValid]
	,[Title]
	,[City]
	,[County]
	,[Region]
	,[PostalSector]
	,[PostCodeDistrict]
	,[PostArea]
	,[CAMEOCode]
	,[Gender]
	,[AgeCurrent]
	,[AgeCurrentBandText]
	,[CashbackPending]
	,[CashbackAvailable]
	,[CashbackLTV]
	,[Unsubscribed]
	,[Hardbounced]
	,[MarketableByEmail]
	,[MarketableByPush]
	,[CurrentlyActive]
	,[RegistrationDate]
	,[DeactivatedDate]
FROM [WH_Virgin].[Derived].[Customer]
