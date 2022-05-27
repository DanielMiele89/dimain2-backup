-- =============================================
-- Author:		JEA
-- Create date: 24/11/2016
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE APW.DirectLoad_CustomerActiveStatus_Fetch 

AS
BEGIN

	SET NOCOUNT ON;

    SELECT FanID
		, ActivatedDate
		, DeactivatedDate
		, OptedOutDate
		, IsRBS
		, ActivationMethodID
	FROM MI.CustomerActiveStatus

END
