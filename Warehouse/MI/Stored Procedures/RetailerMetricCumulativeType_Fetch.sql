
-- =============================================
-- Author:		<Adam Scott>
-- Create date: <02/12/2014>
-- Description:	<Fetches CumlType For Reports>
-- =============================================
CREATE PROCEDURE [MI].[RetailerMetricCumulativeType_Fetch]
	-- Add the parameters for the stored procedure here

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
SELECT [CumulativeTypeID]
  FROM [MI].[RetailerMetricCumulativeType]
  where CumulativeTypeID <>0
END

