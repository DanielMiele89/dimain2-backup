﻿CREATE PROCEDURE dbo.[get_FanMapping_OLD] (@ID INT = 0)
WITH EXECUTE AS OWNER
AS
BEGIN
	SELECT
		ID, SourceUID
	FROM SLC_Report..Fan
	WHERE ID > @ID
END