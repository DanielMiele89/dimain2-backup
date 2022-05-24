-- =============================================
-- Author:		JEA
-- Create date: 27/08/2013
-- Description:	Clears tables for charge-on-redeem calculations
-- =============================================
CREATE PROCEDURE [MI].[ChargeOnRedeem_ClearWorkingTables] 
with execute as owner
AS
BEGIN
	
	SET NOCOUNT ON;

    TRUNCATE TABLE MI.ChargeOnRedeem_Earnings
	TRUNCATE TABLE MI.RedemptionCharge
	TRUNCATE TABLE MI.ChargeOnRedeem_CustomerEligible

END