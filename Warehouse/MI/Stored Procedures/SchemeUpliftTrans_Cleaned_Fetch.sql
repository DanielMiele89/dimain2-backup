-- =============================================
-- Author:		JEA
-- Create date: 14/08/2013
-- Description:	Retrieves entries for SchemeUpliftTrans
-- from the staging area
-- =============================================
CREATE PROCEDURE [MI].[SchemeUpliftTrans_Cleaned_Fetch]
	
AS
BEGIN
	
	SET NOCOUNT ON;

    SELECT s.FileID
		, s.RowNum
		, s.Amount
		, s.AddedDate
		, s.FanID
		, s.OutletID
		, s.PartnerID
		, s.IsOnline
		, s.weekid
		, s.ExcludeTime
		, s.TranDate
		, s.IsRetailReport
		, s.PaymentTypeID
	FROM MI.SchemeUpliftTrans_Stage s
	WHERE s.ExcludeNonTime = 0

END