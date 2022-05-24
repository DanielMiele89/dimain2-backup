-- =============================================
-- Author:		<AJS>
-- Create date: <08/01/2014>
-- Description:	<Deletes Previous Months Customer Entries from staging table>
-- =============================================
Create PROCEDURE [MI].[RetailerReportWipe_StagingCustomer_test]
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	delete from [Warehouse].[MI].[StagingCustomer_test]

END