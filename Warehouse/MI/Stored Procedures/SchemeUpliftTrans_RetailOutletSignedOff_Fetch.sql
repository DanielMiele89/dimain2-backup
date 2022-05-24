-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE MI.SchemeUpliftTrans_RetailOutletSignedOff_Fetch 

AS
BEGIN

	SET NOCOUNT ON;

	SELECT DISTINCT ro.ID as OutletID
	FROM slc_report.dbo.RetailOutlet ro
	INNER JOIN slc_report.dbo.[Partner] p ON ro.PartnerID = p.ID
	INNER JOIN slc_report.dbo.IronOffer o ON p.ID = o.PartnerID
	WHERE O.IsSignedOff = 1

END
