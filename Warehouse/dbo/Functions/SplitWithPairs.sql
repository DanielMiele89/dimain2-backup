CREATE FUNCTION [dbo].[SplitWithPairs]
(
    @List VARCHAR(MAX),
    @MajorDelimiter VARCHAR(1) = ';',
    @MinorDelimiter VARCHAR(1) = ','
)
RETURNS @Items TABLE
(
    Position  INT IDENTITY(1,1) NOT NULL,
    LeftItem  INT NOT NULL,
    RightItem SMALLINT NOT NULL
)
AS
BEGIN
    DECLARE
        @Item      varchar(60),
        @LeftItem  varchar(30),
        @RightItem varchar(30),
        @Pos       INT;

    SELECT
        @List = @List + ' ',
        @MajorDelimiter = LTRIM(RTRIM(@MajorDelimiter)),
        @MinorDelimiter = LTRIM(RTRIM(@MinorDelimiter));

    WHILE LEN(@List) > 0
    BEGIN
        SET @Pos = CHARINDEX(@MajorDelimiter, @List);

        IF @Pos = 0 
            SET @Pos = LEN(@List) + LEN(@MajorDelimiter);

        SELECT
            @Item = LTRIM(RTRIM(LEFT(@List, @Pos - 1))),
            @LeftItem = LTRIM(RTRIM(LEFT(@Item,
            CHARINDEX(@MinorDelimiter, @Item) - 1))),
            @RightItem = LTRIM(RTRIM(SUBSTRING(@Item,
            CHARINDEX(@MinorDelimiter, @Item)
            + LEN(@MinorDelimiter), LEN(@Item))));

        INSERT @Items(LeftItem, RightItem)
            SELECT @LeftItem, @RightItem;

        SET @List = SUBSTRING(@List,
            @Pos + LEN(@MajorDelimiter), DATALENGTH(@List));
    END
    RETURN;
END
