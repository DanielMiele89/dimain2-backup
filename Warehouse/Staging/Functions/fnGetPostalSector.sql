CREATE FUNCTION [Staging].[fnGetPostalSector] ( @pInputPostCode    VARCHAR(8))
RETURNS VARCHAR(6)
BEGIN

    SET @pInputPostCode = CAST(@pInputPostCode AS VARCHAR(8))
    RETURN CASE
		WHEN REPLACE(REPLACE(@pInputPostCode,char(160),''),' ','') like '[a-z][0-9][0-9][a-z][a-z]' Then
				LEFT(replace(replace(@pInputPostCode,char(160),''),' ',''),2)+' '+Right(Left(replace(replace(@pInputPostCode,char(160),''),' ',''),3),1)
		WHEN REPLACE(REPLACE(@pInputPostCode,char(160),''),' ','') like '[a-z][0-9][0-9][0-9][a-z][a-z]' or
				REPLAce(replace(@pInputPostCode,char(160),''),' ','') like '[a-z][a-z][0-9][0-9][a-z][a-z]' or 
				REPLAce(replace(@pInputPostCode,char(160),''),' ','') like '[a-z][0-9][a-z][0-9][a-z][a-z]' Then 
				LEFT(replace(replace(@pInputPostCode,char(160),''),' ',''),3)+' '+Right(Left(replace(replace(@pInputPostCode,char(160),''),' ',''),4),1)
		WHEN REPLACE(REPLACE(@pInputPostCode,char(160),''),' ','') like '[a-z][a-z][0-9][0-9][0-9][a-z][a-z]' or
				REPLAce(replace(@pInputPostCode,char(160),''),' ','') like '[a-z][a-z][0-9][a-z][0-9][a-z][a-z]'Then 
				LEFT(replace(replace(@pInputPostCode,char(160),''),' ',''),4)+' '+Right(Left(replace(replace(@pInputPostCode,char(160),''),' ',''),5),1)
	ELSE ''
END

END