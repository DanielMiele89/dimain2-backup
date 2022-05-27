-- =============================================
-- Author:		JEA
-- Create date: 06/05/2015
-- Description:	
-- =============================================
CREATE PROCEDURE [MI].[ReportPortalUsageRaw_Fetch] 

AS
BEGIN

	SET NOCOUNT ON;

	SELECT ID
		, UserName
		, SUBSTRING(OpDetails, RptStart, RptEnd - RptStart) as rpt
		, UseDate
	FROM
	(
		SELECT ID
			, UserName
			, OpDetails
			, UseDate
			,CHARINDEX('<ReportName>/BankSchemeMIReports/', OpDetails) + 33 AS RptStart
			,CHARINDEX('</ReportName>', OpDetails) AS RptEnd
		FROM MI.ReportPortalUsage_Raw
	) r

END
