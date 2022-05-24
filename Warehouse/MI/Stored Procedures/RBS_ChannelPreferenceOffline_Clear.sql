-- =============================================
-- Author:		JEA
-- Create date: 15/07/2014
-- Description:	Clears the table that tracks RBS customers with offline channel preference
-- =============================================
CREATE PROCEDURE [MI].[RBS_ChannelPreferenceOffline_Clear]
	WITH EXECUTE AS OWNER
AS
BEGIN
	
	SET NOCOUNT ON;

	TRUNCATE TABLE MI.RBS_ChannelPreferenceOffline

END