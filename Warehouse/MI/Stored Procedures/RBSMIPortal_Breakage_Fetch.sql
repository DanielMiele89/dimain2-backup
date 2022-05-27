-- =============================================
-- Author:		JEA
-- Create date: 09/06/2015
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [MI].[RBSMIPortal_Breakage_Fetch]
	
AS
BEGIN

	SET NOCOUNT ON;

	SELECT AdditionalCashbackAdjustmentID AS ID
		, FanID
		, AddedDate AS BreakageDate
		, CashbackEarned AS BreakageAmount
	FROM Relational.AdditionalCashbackAdjustment a
	INNER JOIN Relational.AdditionalCashbackAdjustmentType t ON a.AdditionalCashbackAdjustmentTypeID = t.AdditionalCashbackAdjustmentTypeID
	WHERE t.[Description] LIKE 'Breakage%'
    
END
