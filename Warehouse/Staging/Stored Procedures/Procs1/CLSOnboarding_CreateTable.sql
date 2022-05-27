CREATE PROCEDURE [Staging].[CLSOnboarding_CreateTable] (@FileName VARCHAR(100))

AS
BEGIN

SET NOCOUNT ON

DECLARE @TableName VARCHAR(100) = 'Sandbox.' + SYSTEM_USER + '.[CLSOnboarding_' + REPLACE(@FileName, ' ', '') + ']'
EXEC ('IF OBJECT_ID(''' + @TableName + ''') IS NOT NULL DROP TABLE '+@TableName+'
CREATE TABLE '+@TableName+'([Column 0] [VARCHAR](200) NULL
						  , [Column 1] [VARCHAR](200) NULL
						  , [Column 2] [VARCHAR](200) NULL
						  , [Column 3] [VARCHAR](200) NULL
						  , [Column 4] [VARCHAR](200) NULL
						  , [Column 5] [VARCHAR](200) NULL
						  , [Column 6] [VARCHAR](200) NULL
						  , [Column 7] [VARCHAR](200) NULL
						  , [Column 8] [VARCHAR](200) NULL
						  , [Column 9] [VARCHAR](200) NULL
						  , [Column 10] [VARCHAR](200) NULL
						  , [Column 11] [VARCHAR](200) NULL
						  , [Column 12] [VARCHAR](200) NULL
						  , [Column 13] [VARCHAR](200) NULL
						  , [Column 14] [VARCHAR](200) NULL
						  , [Column 15] [VARCHAR](200) NULL
						  , [Column 16] [VARCHAR](200) NULL
						  , [Column 17] [VARCHAR](200) NULL
						  , [Column 18] [VARCHAR](200) NULL
						  , [Column 19] [VARCHAR](200) NULL
						  , [Column 20] [VARCHAR](200) NULL
						  , [Column 21] [VARCHAR](200) NULL
						  , [Column 22] [VARCHAR](200) NULL
						  , [Column 23] [VARCHAR](200) NULL
						  , [Column 24] [VARCHAR](200) NULL
						  , [Column 25] [VARCHAR](200) NULL
						  , [Column 26] [VARCHAR](200) NULL
						  , [Column 27] [VARCHAR](200) NULL
						  , [Column 28] [VARCHAR](200) NULL
						  , [Column 29] [VARCHAR](200) NULL
						  , [Column 30] [VARCHAR](200) NULL
						  , [Column 31] [VARCHAR](200) NULL
						  , [Column 32] [VARCHAR](200) NULL
						  , [Column 33] [VARCHAR](200) NULL
						  , [Column 34] [VARCHAR](200) NULL
						  , [Column 35] [VARCHAR](200) NULL
						  , [Column 36] [VARCHAR](200) NULL
						  , [Column 37] [VARCHAR](200) NULL
						  , [Column 38] [VARCHAR](200) NULL) ON [PRIMARY]')
END




