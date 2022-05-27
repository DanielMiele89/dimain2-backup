-- =============================================
-- Author:		Shaun
-- Create date: 21/10/2016
-- Description:	Archive and clear
-- =============================================
CREATE PROCEDURE [Prototype].[Archive_Forecasts] 
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	EXEC Warehouse.Prototype.ArchEmpty 'AllQuidco'
	EXEC Warehouse.Prototype.ArchEmpty 'PureQuidco'
	EXEC Warehouse.Prototype.ArchEmpty 'R4G'
	EXEC Warehouse.Prototype.ArchEmpty 'EFR'
	EXEC Warehouse.Prototype.ArchEmpty 'NJ'
	EXEC Warehouse.Prototype.ArchEmpty 'AirtimeRewards'
	EXEC Warehouse.Prototype.ArchEmpty 'SMS'
	EXEC Warehouse.Prototype.ArchEmpty 'CollinsonVirgin'
	EXEC Warehouse.Prototype.ArchEmpty 'CollinsonAvios'
	EXEC Warehouse.Prototype.ArchEmpty 'CollinsonBAA'
	EXEC Warehouse.Prototype.ArchEmpty 'CollinsonUA'
	EXEC Warehouse.Prototype.ArchEmpty 'AMEX'
	EXEC Warehouse.Prototype.ArchEmpty 'TopCashBack'
	EXEC Warehouse.Prototype.ArchEmpty 'Gobsmack_MoreThan'
	EXEC Warehouse.Prototype.ArchEmpty 'Gobsmack_Mustard'

END
