-- =============================================
-- Author:		<Adam Scott>
-- Create date: <20/02/2015>
-- Description:	<Retailer_LapsedPeriod>
-- =============================================
Create PROCEDURE [MI].[Retailer_LapsedPeriod] (@PartnerID int)
	-- Add the parameters for the stored procedure here

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
--declare @Partnerid int
--set @Partnerid = 3960
SELECT [PartnerGroupID]
      ,[PartnerID]
      ,[Months]
      ,[UpdatedDate]
  FROM [Warehouse].[Stratification].[LapsersDefinition]
 where PartnerID = @Partnerid
  order by PartnerID
END