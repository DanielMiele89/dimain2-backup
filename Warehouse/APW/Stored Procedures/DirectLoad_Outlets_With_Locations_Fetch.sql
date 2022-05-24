/******************************************************************************
Author: Jason Shipp
Created: 22/04/2020
Purpose: 
	- Fetches outlets, with location data, for loading onto APW 
	
------------------------------------------------------------------------------
Modification History

******************************************************************************/
CREATE PROCEDURE [APW].[DirectLoad_Outlets_With_Locations_Fetch]
	
AS
BEGIN
	
	SET NOCOUNT ON;

	SELECT	ro.ID AS OutletID
		,	ro.PartnerID
		,	CASE
				WHEN ro.Channel = 1 THEN 1
				ELSE 0
			END AS IsOnline
		,	ro.PartnerOutletReference
		,	ro.MerchantID
		,	ro.MerchantCategoryCode
		,	ro.MerchantNarrative
		,	ro.MerchantLocation
		,	ro.MerchantState
		,	ro.MerchantCountry
		,	fa.Address1
		,	fa.Address2
		,	fa.City
		,	fa.Postcode
		,	fa2.PostalSector
		,	fa2.PostArea
		,	pa.Region
	FROM [SLC_REPL].[dbo].[RetailOutlet] ro
	INNER JOIN [SLC_Report].[dbo].[Fan] fa
		ON ro.FanID = fa.ID
	CROSS APPLY (	SELECT	PostalSector =	CASE
												WHEN REPLACE(REPLACE(PostCode, CHAR(160),''),' ','') like '[a-z][0-9][0-9][a-z][a-z]'
													Then Left(REPLACE(REPLACE(PostCode, CHAR(160),''),' ',''),2)+' '+Right(Left(REPLACE(REPLACE(PostCode, CHAR(160),''),' ',''),3),1)
												WHEN REPLACE(REPLACE(PostCode, CHAR(160),''),' ','') like '[a-z][0-9][0-9][0-9][a-z][a-z]'
												OR REPLACE(REPLACE(PostCode, CHAR(160),''),' ','') like '[a-z][a-z][0-9][0-9][a-z][a-z]'
												OR REPLACE(REPLACE(PostCode, CHAR(160),''),' ','') like '[a-z][0-9][a-z][0-9][a-z][a-z]'
													Then Left(REPLACE(REPLACE(PostCode, CHAR(160),''),' ',''),3)+' '+Right(Left(REPLACE(REPLACE(PostCode, CHAR(160),''),' ',''),4),1)
												WHEN REPLACE(REPLACE(PostCode, CHAR(160),''),' ','') like '[a-z][a-z][0-9][0-9][0-9][a-z][a-z]' 
												OR REPLACE(REPLACE(PostCode, CHAR(160),''),' ','') like '[a-z][a-z][0-9][a-z][0-9][a-z][a-z]'
													Then Left(REPLACE(REPLACE(PostCode, CHAR(160),''),' ',''),4)+' '+Right(Left(REPLACE(REPLACE(PostCode, CHAR(160),''),' ',''),5),1)
												ELSE ''
											END
						,	PostArea =	CASE 
											WHEN PostCode like '[A-Z][0-9]%' then left(PostCode,1) 
											ELSE left(PostCode,2) 
										END
					FROM [SLC_Report].[dbo].[Fan] fa2
					WHERE fa.ID = fa2.ID) fa2
	LEFT JOIN [Staging].[PostArea] pa
		on fa2.PostArea = pa.PostAreaCode

END