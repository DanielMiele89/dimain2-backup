-- =============================================
-- Author:		JEA
-- Create date: 17/12/2013
-- Description:	Retrieves call centre query list for MI portal
-- =============================================
CREATE PROCEDURE [MI].[SchemeMI_CallCentreQuery_Load] 
	
AS
BEGIN
	
	SET NOCOUNT ON;

    SELECT q.ID
		, q.ObjectID AS FanID
		, CAST(q.[Date] AS DATE) As QueryDate
		, CAST(co.[Description] AS VARCHAR(50)) AS QueryType
	FROM slc_report.dbo.Comments q
	INNER JOIN slc_report.dbo.CustomerContactCode co ON q.CustomerContactCodeID = co.ID
	INNER JOIN slc_report.dbo.Fan c ON q.ObjectID = c.ID  --join on objectID NOT fanID
	WHERE q.ObjectTypeID = 1 -- customer query
	AND q.Comment != 'Member activated through one click activation.'
	ORDER BY QueryDate DESC

END