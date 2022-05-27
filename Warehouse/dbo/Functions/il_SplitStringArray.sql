CREATE FUNCTION [dbo].[il_SplitStringArray]
(
    @ItemList NVARCHAR(MAX), 
    @Delimiter NCHAR(1)
)
RETURNS @IDTable TABLE (ID INT IDENTITY(1,1), Item VARCHAR(50))  
AS      

BEGIN    
    DECLARE @tempItemList NVARCHAR(MAX)
    SET @tempItemList = @ItemList

    DECLARE @i INT    
    DECLARE @Item NVARCHAR(MAX)

    SET @tempItemList = REPLACE (@tempItemList, ' ', '')
    SET @i = CHARINDEX(@delimiter, @tempItemList)

    WHILE (LEN(@tempItemList) > 0)
    BEGIN
        IF @i = 0
            SET @Item = @tempItemList
        ELSE
            SET @Item = LEFT(@tempItemList, @i - 1)
        INSERT INTO @IDTable(Item) VALUES(@Item)
        IF @i = 0
            SET @tempItemList = ''
        ELSE
            SET @tempItemList = RIGHT(@tempItemList, LEN(@tempItemList) - @i)
        SET @i = CHARINDEX(@delimiter, @tempItemList)
    END 
    RETURN
END


