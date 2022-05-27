-- =============================================
-- Author:		JEA
-- Create date: 01/12/2016
-- Description:	Fetches PartnerAlternate for SLC_Report direct load
-- =============================================
CREATE PROCEDURE APW.PartnerAlternate_Fetch 

AS
BEGIN

	SET NOCOUNT ON;

    SELECT PartnerID
		, AlternatePartnerID
	FROM APW.PartnerAlternate

END
