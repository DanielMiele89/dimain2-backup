-- =============================================
-- Author:		JEA
-- Create date: 19/08/2015
-- Description:	
-- =============================================
CREATE PROCEDURE MI.SchemeUpliftTrans_BlueIncOfficersClub_Archive_Fetch

AS
BEGIN

	SET NOCOUNT ON;

	SELECT FileID
		, RowNum
		, Amount
		, AddedDate
		, FanID
		, OutletID
		, PartnerID
		, IsOnline
		, WeekID
		, ExcludeTime
		, TranDate
		, IsRetailReport
		, PaymentTypeID
	FROM InsightArchive.SUTBlueIncOfficersClub

END
