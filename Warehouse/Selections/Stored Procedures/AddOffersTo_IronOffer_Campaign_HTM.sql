/*
Author:		Suraj Chahal
Date:		29/08/2013
Purpose:	Run subsequent to IronOfferMember Populated to pull through extra information:
				a). HTM - For which headroom segment the offer is reffering to; this is NULL for universal offers
				b). ClientServicesRef - Used to group offers together
		This data will be used later to work out if offers or above or equal to base offer rates

*/

CREATE PROCEDURE [Selections].[AddOffersTo_IronOffer_Campaign_HTM]

AS
BEGIN
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

DECLARE @Qry NVARCHAR(MAX)

DECLARE	@TableID INT = (SELECT MIN(TableID) FROM [Selections].[CampaignExecution_TableNames])
	,	@TableIDMax INT = (SELECT MAX(TableID) FROM [Selections].[CampaignExecution_TableNames])
	,	@TableName VARCHAR(MAX)


WHILE @TableID <= @TableIDMax
	BEGIN
		
		SELECT @TableName = TableName
		FROM [Selections].[CampaignExecution_TableNames]
		WHERE TableID = @TableID

		SET @Qry =	'IF OBJECT_ID(''tempdb..#Offers'') IS NOT NULL DROP TABLE #Offers
				SELECT	DISTINCT
					ClientServicesRef,
					PartnerID,
					NULL					as EPOCU,
					NULL					as HTMSegment,
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
				INSERT INTO [Warehouse].[Relational].[IronOffer_Campaign_HTM]
				SELECT * 
				FROM #Offers as o
				WHERE o.IronOfferID NOT IN (SELECT DISTINCT IronOfferID FROM [Warehouse].[Relational].[IronOffer_Campaign_HTM])'
		
		--SELECT @Qry
		exec sp_executesql @Qry
		
		SELECT @TableID = MIN(TableID)
		FROM [Selections].[CampaignExecution_TableNames]
		WHERE @TableID < TableID

	END

END