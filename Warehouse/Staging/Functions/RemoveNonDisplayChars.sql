CREATE FUNCTION Staging.RemoveNonDisplayChars
--===== Declare the I/O parameters
        (@pString VARCHAR(8000))
RETURNS VARCHAR(8000) 
     AS
  BEGIN

--===== Declare Local variables
DECLARE @IncorrectCharLoc SMALLINT, --Position of bad character
        @Pattern          CHAR(37)  --Bad characters to look for

 SELECT @Pattern          = '%['
                          + CHAR(0)+CHAR(1)+CHAR(2)+CHAR(3)+CHAR(4)
                          + CHAR(5)+CHAR(6)+CHAR(7)+CHAR(8)+CHAR(9)
                          + CHAR(10)+CHAR(11)+CHAR(12)+CHAR(13)+CHAR(14)
                          + CHAR(15)+CHAR(16)+CHAR(17)+CHAR(18)+CHAR(19)
                          + CHAR(20)+CHAR(21)+CHAR(22)+CHAR(23)+CHAR(24)
                          + CHAR(25)+CHAR(26)+CHAR(27)+CHAR(28)+CHAR(29)
                          + CHAR(30)+CHAR(31)+CHAR(127)
                          + ']%',
        @IncorrectCharLoc = PATINDEX(@Pattern, @pString)

  WHILE @IncorrectCharLoc > 0
 SELECT @pString          = STUFF(@pString, @IncorrectCharLoc, 1, ''),
        @IncorrectCharLoc = PATINDEX(@Pattern, @pString)
 RETURN @pString
    END