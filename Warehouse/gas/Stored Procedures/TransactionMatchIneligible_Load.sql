-- =============================================
-- Author:	JEA
-- Create date: 13/08/2013
-- Description:	Loads those transactions that are never eligible for incentivisation
-- =============================================
CREATE PROCEDURE Gas.TransactionMatchIneligible_Load 
	(
		@FileID INT
	)
AS
BEGIN
	
	SET NOCOUNT ON;

	insert into MI.TransMatchIneligible(fileid, rownum)
	select fileid, rownum
	from Archive.dbo.NobleTransactionHistory with (nolock)
	where PostStatus != 'O'
	and PostStatus != 'W'
	and PostStatus != 'M'
	and PostStatus != 'D'
	and fileid = @fileid

END
