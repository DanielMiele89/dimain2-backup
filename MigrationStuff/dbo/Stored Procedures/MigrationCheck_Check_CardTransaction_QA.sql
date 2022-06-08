/*
05/12/2021

The matched count is good until friday 03/12 then DIMAIN2 and DIDEVTEST diverge from DIMAIN. 
This observation shows that the ConsumerCombination table changed, on DIMAIN but not on DIMAIN2 or DIDEVTEST, prior to the friday evening MIDI run.

Also on friday, looking at FileID 34110. 
It was processed long after DB7 feed to Archive_Light on DIMAIN and DIDEVTEST and contained 11,362,967 rows.
It was processed at 08:45 on DIMAIN2 and contained only 49,470 rows - probably because the DB7 feed to Archive_Light hadn't completed.

*/
CREATE PROCEDURE [dbo].[MigrationCheck_Check_CardTransaction_QA] AS 

SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

DECLARE @RowCount BIGINT

IF 1 = 1 BEGIN
	IF OBJECT_ID('tempdb..#CT_QADIMAIN2') IS NOT NULL DROP TABLE #CT_QADIMAIN2;
	SELECT * 
	INTO #CT_QADIMAIN2
	FROM Warehouse.Staging.CardTransaction_QA
	SET @RowCount = @@ROWCOUNT
	--CREATE UNIQUE CLUSTERED INDEX ucx_CIN ON #CT_QADIMAIN2 (CIN)
	-- (17856381 rows affected) / 00:00:25

	IF OBJECT_ID('tempdb..#CT_QADIDEVTEST') IS NOT NULL DROP TABLE #CT_QADIDEVTEST;
	SELECT *
	INTO #CT_QADIDEVTEST 
	FROM OPENQUERY (DIDEVTEST, 'SELECT * FROM Warehouse.Staging.CardTransaction_QA')
	--CREATE UNIQUE CLUSTERED INDEX ucx_CIN ON #CT_QADIDEVTEST (CIN)
	-- (17856381 rows affected) / 00:00:25

	IF OBJECT_ID('tempdb..#CT_QADIMAIN') IS NOT NULL DROP TABLE #CT_QADIMAIN;
	SELECT * 
	INTO #CT_QADIMAIN 
	FROM OPENQUERY (DIMAIN, 'SELECT * FROM Warehouse.Staging.CardTransaction_QA')
	--CREATE UNIQUE CLUSTERED INDEX ucx_CIN ON #CT_QADIMAIN (CIN)
	-- (17856381 rows affected) / 00:00:25
END


SELECT * FROM #CT_QADIMAIN2 ORDER BY FileID DESC
SELECT * FROM #CT_QADIDEVTEST ORDER BY FileID DESC
SELECT * FROM #CT_QADIMAIN ORDER BY FileID DESC


RETURN 0








