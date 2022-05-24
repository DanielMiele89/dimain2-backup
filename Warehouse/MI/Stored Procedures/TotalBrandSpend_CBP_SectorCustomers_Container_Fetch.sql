﻿-- =============================================
-- Author:		JEA
-- Create date: 20/10/2016
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [MI].[TotalBrandSpend_CBP_SectorCustomers_Container_Fetch]
(
	@MyRewardsDataSet TINYINT
)
AS
BEGIN

	SET NOCOUNT ON;

    IF @MyRewardsDataSet = 2
	BEGIN
		EXEC MI.TotalBrandSpend_CBP_SectorCustomers_Fetch -- MyRewards customers regardless of core/private status
	END
	ELSE IF @MyRewardsDataSet = 1
	BEGIN
		EXEC MI.TotalBrandSpend_MyRewards_CorePrivate_SectorCustomers_Fetch 1 --Private
	END
	ELSE --@MyRewardsDataSet = 0
	BEGIN
		EXEC MI.TotalBrandSpend_MyRewards_CorePrivate_SectorCustomers_Fetch 0 --Core
	END

END