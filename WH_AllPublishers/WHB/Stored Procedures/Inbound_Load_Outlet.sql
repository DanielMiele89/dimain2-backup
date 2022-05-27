
CREATE PROCEDURE [WHB].[Inbound_Load_Outlet]
AS
BEGIN

		SET ANSI_WARNINGS OFF

	/*******************************************************************************************************************************************
		1.	Clear down [Inbound].[Outlet] table
	*******************************************************************************************************************************************/
	
		TRUNCATE TABLE [Inbound].[Outlet]


	/*******************************************************************************************************************************************
		2.	Load #RetailOutlet table
	*******************************************************************************************************************************************/

		IF OBJECT_ID('tempdb..#RetailOutlet') IS NOT NULL DROP TABLE #RetailOutlet
		SELECT	OutletID = ro.ID
			,	PartnerID = ro.PartnerID
			,	PartnerOutletReference = ro.PartnerOutletReference
			,	MerchantID = REPLACE(LTRIM(RTRIM(REPLACE(ro.MerchantID, ' ', ''))), '#', '')
			,	Status =	CASE
								WHEN ro.MerchantID LIKE '%#%' THEN 0
								ELSE 1
							END
			,	Channel = ro.Channel					--1 = Online, 2 = Offline
			,	IsOnline = CONVERT(BIT, NULL)
			,	Address1 = LTRIM(RTRIM(fa.Address1))
			,	Address2 = LTRIM(RTRIM(fa.Address2))
			,	City = LTRIM(RTRIM(fa.City))
			,	Postcode = LEFT(LTRIM(RTRIM(fa.Postcode)), 10)
			,	PostalSector = CONVERT(VARCHAR(6), NULL)
			,	PostArea = CONVERT(VARCHAR(2), NULL)
			,	Region = CONVERT(VARCHAR(30), NULL)
			,	RIGHT(co.Coordinates, LEN(co.Coordinates) -  PATINDEX('% %', co.Coordinates)) AS Latitude
			,	LEFT(co.Coordinates, PATINDEX('% %', co.Coordinates) - 1) AS Longitude
		INTO #RetailOutlet
		FROM [SLC_Report].[dbo].[RetailOutlet] ro
		LEFT JOIN [SLC_Report].[dbo].[Fan] fa
			ON ro.FanID = fa.ID
		CROSS APPLY (	SELECT	Coordinates = SUBSTRING(CONVERT(VARCHAR(50), ro.Coordinates), 8, LEN(CONVERT(VARCHAR(50), ro.Coordinates)) - 8)) co

		
	/*******************************************************************************************************************************************
		3.	Enhance Data in #RetailOutlet
	*******************************************************************************************************************************************/

		UPDATE ro
		SET	PostalSector =	CASE
								WHEN PostCode_SpacesRemoved LIKE '[a-z][0-9][0-9][a-z][a-z]' THEN LEFT(PostCode_SpacesRemoved, 2) + ' ' + RIGHT(LEFT(PostCode_SpacesRemoved, 3), 1)

								WHEN PostCode_SpacesRemoved LIKE '[a-z][0-9][0-9][0-9][a-z][a-z]' THEN LEFT(PostCode_SpacesRemoved, 3) + ' ' + RIGHT(LEFT(PostCode_SpacesRemoved, 4), 1)
								WHEN PostCode_SpacesRemoved LIKE '[a-z][a-z][0-9][0-9][a-z][a-z]' THEN LEFT(PostCode_SpacesRemoved, 3) + ' ' + RIGHT(LEFT(PostCode_SpacesRemoved, 4), 1)
								WHEN PostCode_SpacesRemoved LIKE '[a-z][0-9][a-z][0-9][a-z][a-z]' THEN LEFT(PostCode_SpacesRemoved, 3) + ' ' + RIGHT(LEFT(PostCode_SpacesRemoved, 4), 1)

								WHEN PostCode_SpacesRemoved LIKE '[a-z][a-z][0-9][0-9][0-9][a-z][a-z]' THEN LEFT(PostCode_SpacesRemoved, 4) + ' ' + RIGHT(LEFT(PostCode_SpacesRemoved, 5), 1)
								WHEN PostCode_SpacesRemoved LIKE '[a-z][a-z][0-9][a-z][0-9][a-z][a-z]' THEN LEFT(PostCode_SpacesRemoved, 4) + ' ' + RIGHT(LEFT(PostCode_SpacesRemoved, 5), 1)

								ELSE ''
							END
		,	PostArea =		CASE 
								WHEN PostCode LIKE '[A-Z][0-9]%' THEN LEFT(PostCode, 1)
								ELSE LEFT(PostCode, 2)
							END
		,	IsOnline =		CASE 
								WHEN Channel = 1 THEN 1	--	Channel = 1 represents an online outlet
								ELSE 0
							END
		FROM #RetailOutlet ro
		CROSS APPLY (	SELECT PostCode_SpacesRemoved = REPLACE(REPLACE(PostCode, CHAR(160), ''), ' ', '')) pc

		UPDATE ro
		SET	ro.Region = pa.Region
		FROM #RetailOutlet ro
		INNER JOIN [Warehouse].[Staging].[PostArea] pa
			ON ro.PostArea = pa.PostAreaCode
		

	/*******************************************************************************************************************************************
		4.	Insert to [Inbound].[Outlet]
	*******************************************************************************************************************************************/

		INSERT INTO [Inbound].[Outlet]
		SELECT	OutletID
			,	PartnerID
			,	PartnerOutletReference
			,	MerchantID
			,	Status
			,	Channel
			,	IsOnline
			,	Address1
			,	Address2
			,	City
			,	Postcode
			,	PostalSector
			,	PostArea
			,	Region
			,	Latitude
			,	Longitude
		FROM #RetailOutlet

END


