-- =============================================
-- Author:		JEA
-- Create date: 26/04/2016
-- Description:	Retrieves list of partners eligible for market share analysis
-- =============================================
CREATE PROCEDURE [APW].[MarketShareBrandList_Fetch] 
	
AS
BEGIN

	SET NOCOUNT ON;

	SELECT BrandID, PartnerID
	FROM APW.ControlRetailers

END