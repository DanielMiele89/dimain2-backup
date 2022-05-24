
-- ***************************************************************************
-- Author: Suraj Chahal
-- Create date: 16/10/2014
-- Description: Report to pull top level stats for offers going live that week
-- ***************************************************************************
CREATE PROCEDURE [Staging].[SSRS_R0074_CampaignListV1_1]
--	WITH EXECUTE AS OWNER	
AS
BEGIN
	SET NOCOUNT ON;
	
	/**************************************************************************
		1. Create table and prepare parameters to loop through selections
	**************************************************************************/

		IF OBJECT_ID('tempdb..#SSRS_R0074_CampaignList') IS NOT NULL DROP TABLE #SSRS_R0074_CampaignList
		CREATE TABLE #SSRS_R0074_CampaignList (ClientServicesRef VARCHAR(15)
											 , OfferID INT)

		DECLARE @StartRow INT = 1
			  , @Qry NVARCHAR(MAX)
			  , @TableName VARCHAR(100)
	

	/**************************************************************************
		2. Loop through selections table to find all offers
	**************************************************************************/

		WHILE @StartRow <= (SELECT MAX(TableID) FROM [Selections].[CampaignExecution_TableNames])
			BEGIN

				SET @TableName = (SELECT TableName FROM [Selections].[CampaignExecution_TableNames] WHERE TableID = @StartRow)

				SET @Qry = 'INSERT INTO #SSRS_R0074_CampaignList
							SELECT DISTINCT
								   ClientServicesRef
								 , OfferID
							FROM ' + @TableName

				EXEC (@Qry)

				SET @StartRow = @StartRow + 1

		END
	

	/**************************************************************************
		3. Output for report
	**************************************************************************/

		SELECT DISTINCT
			   pa.PartnerName
			 , cl.ClientServicesRef
			 , COALESCE(cn.CampaignName, iof.IronOfferName) as CampaignName
		FROM #SSRS_R0074_CampaignList cl
		INNER JOIN Relational.IronOffer iof
			ON cl.OfferID = iof.IronOfferID
		INNER JOIN Relational.Partner pa
			ON iof.PartnerID = pa.PartnerID
		LEFT JOIN Warehouse.Relational.CBP_CampaignNames cn
			ON cl.ClientServicesRef = cn.ClientServicesRef
		WHERE EXISTS (SELECT 1
					  FROM iron.OfferMemberAddition oma
					  WHERE cl.OfferID = oma.IronOfferID)
		ORDER BY ClientServicesRef

END
GO
GRANT EXECUTE
    ON OBJECT::[Staging].[SSRS_R0074_CampaignListV1_1] TO [gas]
    AS [dbo];

