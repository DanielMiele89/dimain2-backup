-- =============================================
-- Author:		AJS
-- Create date: 13/06/2014
-- Description:	Clears down the ReportMID Staging tables
-- =============================================
CREATE PROCEDURE [MI].[ReportMID_Clear]
	WITH EXECUTE AS OWNER
AS
BEGIN
	
	SET NOCOUNT ON;

    TRUNCATE TABLE MI.ReportMID_Staging_Part1
	TRUNCATE TABLE MI.ReportMID_Staging_Part2
	TRUNCATE TABLE MI.ReportMID_Staging_part3
	TRUNCATE TABLE MI.ReportMID_Staging_part4

END