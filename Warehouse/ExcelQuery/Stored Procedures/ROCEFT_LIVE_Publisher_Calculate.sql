-- =============================================
-- S.H., Populate Publisher Table for later SP
-- =============================================
CREATE PROCEDURE [ExcelQuery].[ROCEFT_LIVE_Publisher_Calculate]
AS
BEGIN
	SET NOCOUNT ON;

	DECLARE @time DATETIME

	EXEC Prototype.oo_TimerMessage 'ROCEFT - Publisher Start', @time OUTPUT

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
			,(159,'Complete Savings','Random')
			,(NULL,'HSBC Advance','Random')
			,(158,'Gobsmack - Admiral','Random')
			,(161,'Gobsmack - Thomas Cook','Random')
			,(NULL,'Gobsmack - Ageas','Random')
			,(NULL,'Monzo','Random')
			,(NULL,'Virgin Money VGLC','Random')

	EXEC Prototype.oo_TimerMessage 'ROCEFT - Publisher End', @time OUTPUT

END
