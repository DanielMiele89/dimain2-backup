CREATE PROCEDURE [Prototype].[DataValidation_CreateTable_RP]
(
	@FileName VARCHAR(30)
)
AS
BEGIN

	 SET NOCOUNT ON

	DECLARE @TableName VARCHAR(100) = 'Sandbox.'+system_user + '.[DataValHM_' + REPLACE(@FileName, ' ', '') + ']'
	EXEC ('
		IF OBJECT_ID('''+@TableName+''') IS NOT NULL DROP TABLE '+@TableName+'
		CREATE TABLE '+@TableName+'(
			
		--	[ClubCashAvailable] [varchar](50) NULL,
		--	[ClubID] [varchar](50) NULL,
			
			[Email] [varchar](500) NULL,
			[Homemover] [varchar](50) NULL,
			[FANID] [varchar](50) NULL

		) ON [PRIMARY]
	')
END



