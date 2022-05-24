-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE gas.SampleGetBrandIDs 
	(
		@ArbitID tinyint
	)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    select brandid
    from staging.brandassoc
    where arbitraryid = @ArbitID
END
GO
GRANT EXECUTE
    ON OBJECT::[gas].[SampleGetBrandIDs] TO [DB5\reportinguser]
    AS [dbo];

