/******************************************************************************
-- Author:		Hayden Reid
-- Create date: 01/09/2020
-- Description:	Fetch the set of rows for the Name Dictionary file

------------------------------------------------------------------------------
Modification History

[Date] [User]
	- [Description]

******************************************************************************/
CREATE PROCEDURE [Processing].[FileExtraction_Names_Fetch]
AS
BEGIN

	IF 1=1
		THROW 52345
		, 'This should not be run accidentally since it will create a file and cause more confusion than necessary.
		If required, manually change the stored procedure to make it runnable.'
		, 1

	SELECT
		isLastName,
		Unmasked AS Name
	FROM Processing.Masking_NameDictionary

	RETURN @@rowcount

END
