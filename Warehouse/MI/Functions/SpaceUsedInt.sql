-- =============================================
-- Author:		JEA
-- Create date: 10/12/2015
-- Description:	turns a string from the sp_spaceused 
-- procedure into an int
-- =============================================
CREATE FUNCTION [MI].[SpaceUsedInt] 
(
	@StringValue VARCHAR(50)
)
RETURNS BIGINT
AS
BEGIN
	-- Declare the return variable here
	DECLARE @ReturnInt BIGINT

	IF @StringValue IS NULL OR @StringValue = 'NULL'
	BEGIN
		SET @ReturnInt = NULL
	END
	ELSE
	BEGIN
		SET @ReturnInt = CAST(REPLACE(@StringValue, ' KB', '') AS BIGINT)
	END
	
	RETURN @ReturnInt

END