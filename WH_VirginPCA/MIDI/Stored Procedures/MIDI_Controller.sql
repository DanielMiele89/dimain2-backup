
CREATE PROCEDURE [MIDI].[MIDI_Controller]

AS

SET NOCOUNT ON
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

DECLARE @ProcessName VARCHAR(50), @Activity VARCHAR(200), @time DATETIME = GETDATE(), @SSMS BIT 

SET @Activity = ISNULL(OBJECT_NAME(@@PROCID),'SSMS') + ' - Start'; EXEC Monitor.ProcessLogger 'MIDI', @Activity, @time OUTPUT, @SSMS OUTPUT


EXEC [MIDI].[Inbound_FilesToProcess]

DECLARE @FileIDsToRun INT = 1

WHILE 0 < @FileIDsToRun
	BEGIN
	
		EXEC [MIDI].[GenericTransExtracter_DCTrans] -- 8125848 / 00:03:23

		EXEC [MIDI].[GenericTransProcessing] -- 8018275+9536 / 00:11:02
		
		SELECT @FileIDsToRun = COUNT(*)
		FROM [WHB].[Inbound_Files] f
		WHERE TableName = 'Transactions'
		AND FileProcessed = 0

	END

EXEC [MIDI].[GenericTransProcessing_MIDIHolding] -- 8018275+9536 / 00:11:02

EXEC [MIDI].[GenericTransLoader]

IF (SELECT DATENAME(WEEKDAY, GETDATE())) = 'Sunday' EXEC [MIDI].[ManualModule]

SET @Activity = ISNULL(OBJECT_NAME(@@PROCID),'SSMS') + ' - Complete'; EXEC Monitor.ProcessLogger 'MIDI', @Activity, @time OUTPUT, @SSMS OUTPUT


EXEC msdb.dbo.sp_send_dbmail 
        @profile_name = 'Administrator', 
		@recipients='DIProcessCheckers@rewardinsight.com',
        @subject = 'VirginWH MID Identification process COMPLETE',
        @body='Notification email to confirm that the MID Identification process on DIMAIN has completed',
        @body_format = 'TEXT',  
        @exclude_query_output = 1



RETURN 0 


