-- =============================================
-- Author:		<Adam Scott>
-- Create date: <23/06/2014>
-- Description:	<Loads partners in importlist>
-- =============================================
CREATE PROCEDURE [MI].[ReportMID_Staging_Partner_load]
	-- Add the parameters for the stored procedure here
	WITH EXECUTE AS OWNER
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	Truncate Table MI.ReportMID_Staging_Partner
	Insert into MI.ReportMID_Staging_Partner (PartnerID)
	select PartnerID From MI.ReportMID_Staging_Part2 group by PartnerID
END
