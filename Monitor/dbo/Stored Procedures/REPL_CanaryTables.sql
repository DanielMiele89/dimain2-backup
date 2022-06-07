
CREATE PROCEDURE [dbo].[REPL_CanaryTables] 

	@DBName VARCHAR(50)

AS

/*
Keep this in the Monitor db
*/

SET NOCOUNT ON; 
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED;

SELECT r.ID, 
	Delay_1	= CASE WHEN a.[Delay] < 61 THEN 1 ELSE a.[Delay] - 60 END, 
	Delay_2	= CASE WHEN b.[Delay] < 61 THEN 1 ELSE b.[Delay] - 60 END,
	Delay_3	= CASE WHEN c.[Delay] < 61 THEN 1 ELSE c.[Delay] - 60 END,
	Delay_4	= CASE WHEN d.[Delay] < 61 THEN 1 ELSE d.[Delay] - 60 END,
	Delay_5	= CASE WHEN e.[Delay] < 61 THEN 1 ELSE e.[Delay] - 60 END,
	Delay_6	= CASE WHEN f.[Delay] < 61 THEN 1 ELSE f.[Delay] - 60 END,
	Delay_7	= CASE WHEN g.[Delay] < 61 THEN 1 ELSE g.[Delay] - 60 END,
	Delay_8	= CASE WHEN h.[Delay] < 61 THEN 1 ELSE h.[Delay] - 60 END,
	Delay_9	= ISNULL(CASE WHEN i.[Delay] < 61 THEN 1 ELSE i.[Delay] - 60 END,0),
	Delay_10	= CASE WHEN j.[Delay] < 61 THEN 1 ELSE j.[Delay] - 60 END
FROM (SELECT ID = 1) r
OUTER APPLY (SELECT [Delay] = DATEDIFF(SECOND,[LastUpdate],GETDATE()) FROM [SLC_REPL].[REPL].[Canary_Comments]) a
OUTER APPLY (SELECT [Delay] = DATEDIFF(SECOND,[LastUpdate],GETDATE()) FROM [SLC_REPL].[REPL].[Canary_EmailActivity]) b
OUTER APPLY (SELECT [Delay] = DATEDIFF(SECOND,[LastUpdate],GETDATE()) FROM [SLC_REPL].[REPL].[Canary_Fan]) c
OUTER APPLY (SELECT [Delay] = DATEDIFF(SECOND,[LastUpdate],GETDATE()) FROM [SLC_REPL].[REPL].[Canary_IronOfferMember]) d
OUTER APPLY (SELECT [Delay] = DATEDIFF(SECOND,[LastUpdate],GETDATE()) FROM [SLC_REPL].[REPL].[Canary_Match]) e
OUTER APPLY (SELECT [Delay] = DATEDIFF(SECOND,[LastUpdate],GETDATE()) FROM [SLC_REPL].[REPL].[Canary_Pan]) f
OUTER APPLY (SELECT [Delay] = DATEDIFF(SECOND,[LastUpdate],GETDATE()) FROM [SLC_REPL].[REPL].[Canary_PaymentCard]) g
OUTER APPLY (SELECT [Delay] = DATEDIFF(SECOND,[LastUpdate],GETDATE()) FROM [SLC_REPL].[REPL].[Canary_SmallTables]) h
OUTER APPLY (SELECT [Delay] = DATEDIFF(SECOND,[LastUpdate],GETDATE()) FROM [SLC_REPL].[REPL].[Canary_SmallTables2]) i
OUTER APPLY (SELECT [Delay] = DATEDIFF(SECOND,[LastUpdate],GETDATE()) FROM [SLC_REPL].[REPL].[Canary_Trans]) j
	
RETURN 0

GO
GRANT EXECUTE
    ON OBJECT::[dbo].[REPL_CanaryTables] TO [PRTGBuddy]
    AS [dbo];

