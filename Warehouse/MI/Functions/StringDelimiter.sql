/******************************************************************************
Author	  Hayden Reid
Created	  12/12/2016
Purpose	  Returns a delimited list by parameter that is delimited by newline (useful
		  when copying columns out of a table)

Copyright © 2016, Reward, All Rights Reserved
------------------------------------------------------------------------------
Modification History

01/01/0000 Developer Full Name
A comprehensive description of the changes. The description may use as 
many lines as needed.

******************************************************************************/
CREATE FUNCTION [MI].[StringDelimiter]
(
    @String NVARCHAR(MAX)
    , @Delimiter NVARCHAR(10) = ','
)
RETURNS NVARCHAR(MAX)
AS
BEGIN
	
	RETURN REPLACE(@String, CHAR(13) + CHAR(10), @Delimiter)
END
