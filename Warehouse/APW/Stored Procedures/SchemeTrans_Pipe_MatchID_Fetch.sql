-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE APW.SchemeTrans_Pipe_MatchID_Fetch 

AS
BEGIN

	SET NOCOUNT ON;

    SELECT MAX(ID) AS MatchID
	FROM APW.SchemeTrans_Pipe

END