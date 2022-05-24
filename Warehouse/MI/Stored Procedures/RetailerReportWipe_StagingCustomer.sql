-- =============================================
-- Author:		<AJS>
-- Create date: <15/10/2013>
-- Description:	<Deletes Previous Months Customer Entries from staging table>
-- =============================================
CREATE PROCEDURE [MI].[RetailerReportWipe_StagingCustomer]
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	TRUNCATE TABLE [Warehouse].[MI].[StagingCustomer]

END