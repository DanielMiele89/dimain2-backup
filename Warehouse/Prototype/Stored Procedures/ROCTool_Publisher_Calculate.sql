-- =============================================
-- Author:		<Shaun H>
-- Create date: <30/01/2019>
-- Description:	<Strip out Publisher Table Population from the now defunct ROCEFT_CumulGainsBase>
-- =============================================
CREATE PROCEDURE Prototype.ROCTool_Publisher_Calculate
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	TRUNCATE TABLE Warehouse.ExcelQuery.ROCEFT_Publishers

	INSERT INTO Warehouse.ExcelQuery.ROCEFT_Publishers
		Values
			(144,'Airtime Rewards','Random')
			,(148,'Collinson - Avios','Random')
			,(149,'Collinson - BAA','Random')
			,(147,'Collinson - Virgin','Random')
			,(156,'Collinson - UA','Random')
			,(155,'Gobsmack - More Than','Random')
			,(157,'Gobsmack - Mustard','Random')
			,(12,'Quidco','Ranked')
			,(145,'Next Jump','Random')
			,(NULL,'RBS','Other')
			,(NULL,'Top Cashback','Random')
			,(NULL,'Complete Savings','Random')
			,(NULL,'HSBC Advance','Random')
			,(NULL,'Gobsmack - Admiral','Random')
END
