-- =============================================
-- Author:		<Adam scott>
-- Create date: <05/12/2014>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [MI].[Retaileroldimportloop]
	-- Add the parameters for the stored procedure here

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
Select id from Relational.SchemeUpliftTrans_Month where id between 20 and 34
order by id
END