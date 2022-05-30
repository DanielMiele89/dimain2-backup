/******************************************************************************
-- Author:		Hayden Reid
-- Create date: 01/09/2020
-- Description:	Fetch the set of rows for the MIDTuple Matching file based
				on the date the file was produced

------------------------------------------------------------------------------
Modification History

[Date] [User]
	- [Description]

******************************************************************************/
CREATE PROCEDURE [Processing].[FileExtraction_MIDTupleMatching_Fetch]
(
	@FileDate DATE -- The date the file was produced
)
AS
BEGIN

	SELECT
		TempProxyMIDTupleID
		, ProxyMIDTupleID
	FROM Processing.MIDTupleMatching mtm
	WHERE FileDate = @FileDate

	RETURN @@rowcount

END
