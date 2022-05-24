-- =============================================
-- Author:		JEA
-- Create date: 15/09/2014
-- Description:	
-- =============================================
CREATE PROCEDURE [RewardBI].[Outlet_AllSchemes_Clear] 
	WITH EXECUTE AS OWNER
AS
BEGIN

	SET NOCOUNT ON;

    TRUNCATE TABLE RewardBI.Outlet_AllSchemes

END