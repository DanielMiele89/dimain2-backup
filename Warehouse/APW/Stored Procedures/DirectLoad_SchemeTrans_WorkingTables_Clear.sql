-- =============================================
-- Author:			JEA
-- Create date: 06/12/2016
-- Description:	Clear working tables for scheme trans direct load
-- =============================================
CREATE PROCEDURE [APW].[DirectLoad_SchemeTrans_WorkingTables_Clear] 
	WITH EXECUTE AS OWNER
AS
BEGIN

	SET NOCOUNT ON;

	TRUNCATE TABLE APW.DirectLoad_IronOfferSpendStretch
	TRUNCATE TABLE APW.DirectLoad_PublisherIDs
	TRUNCATE TABLE APW.DirectLoad_PublisherExclude
	TRUNCATE TABLE APW.DirectLoad_RetailerOnline
	TRUNCATE TABLE APW.Retailer
	TRUNCATE TABLE APW.DirectLoad_PartnerDeals	--	?
	TRUNCATE TABLE APW.DirectLoad_RetailOutlet

END