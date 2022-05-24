
CREATE FUNCTION [dbo].[SplitInts]
(
    @str VARCHAR(MAX)
)
RETURNS @Items TABLE
(
    ID Int
)
AS
BEGIN

	DECLARE @x XML 
	SELECT @x = CAST('<A>'+ REPLACE(@str,',','</A><A>')+ '</A>' AS XML)

	INSERT INTO @Items(ID)   
	SELECT t.value('.', 'int') AS inVal
	FROM @x.nodes('/A') as x(t)
  
    RETURN;
END