﻿-- =============================================
-- Author:		JEA
-- Create date: 15/06/2016
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [APW].[ControlMethod_ControlRetailers_Fetch] 

AS
BEGIN

	SET NOCOUNT ON;

	SELECT PartnerID AS RetailerID, BrandID
	FROM APW.ControlRetailers
	--WHERE PartnerID in (4565,4569)
	ORDER BY RetailerID

END