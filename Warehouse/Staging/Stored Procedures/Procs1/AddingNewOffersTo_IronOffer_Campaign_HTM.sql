/*
Author:		Suraj Chahal
Date:		29/08/2013
Purpose:	Run subsequent to IronOfferMember Populated to pull through extra information:
				a). HTM - For which headroom segment the offer is reffering to; this is NULL for universal offers
				b). ClientServicesRef - Used to group offers together
		This data will be used later to work out if offers or above or equal to base offer rates

*/

CREATE PROCEDURE [Staging].[AddingNewOffersTo_IronOffer_Campaign_HTM]
	@Tablename nvarchar(150),
	@HTM BIT
AS


--SET @Tablename = 'Sandbox.suraj.CN001_CaffeNeroSelection'
--SET @HTM = 1

BEGIN

DECLARE @Qry nvarchar(MAX)
	  --, @Tablename nvarchar(150) = 'Warehouse.Selections.MOR019_Selection_Script_1'
	  --, @HTM BIT = 1

SET @Qry =	'SELECT	DISTINCT
			ClientServicesRef,
			PartnerID,
			NULL					as EPOCU,
			'+
			CASE	WHEN @HTM = 1	THEN 'HTMID' 
				ELSE 'NULL'
			END +'					as HTMSegment,
			OfferID					as IronOfferID,
			NULL					as CashBackRate,
			NULL					as CommissionRate,
			NULL					as BaseOfferID,
			NULL					as Base_CashbackRate,
			NULL					as Base_CommissionRate,
			NULL					as AboveBase,
			0					as isConditionalOffer
		INTO #Offers
		FROM' +' '+ @Tablename 
		+' 
		ORDER BY IronOfferID
		'+
		'
		INSERT INTO warehouse.Relational.IronOffer_Campaign_HTM
		SELECT * 
		FROM #Offers as o
		WHERE o.IronOfferID NOT IN (SELECT DISTINCT IronOfferID FROM warehouse.Relational.IronOffer_Campaign_HTM)'
		
--SELECT @Qry
exec sp_executesql @Qry

--SELECT * FROM warehouse.Relational.IronOffer_Campaign_HTM ORDER BY IronOfferID,HTMSegment 

END



