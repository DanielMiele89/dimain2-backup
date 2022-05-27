/******************************************************************************
Author: Jason Shipp
Created: 03/10/2018
Purpose: 
	- Add new dates to direct debit AWS-dates-loaded-to-file log table (Archive_Light.dbo.CBP_DirectDebit_DatesLoadedToFileLog)
------------------------------------------------------------------------------
Modification History

******************************************************************************/
CREATE PROCEDURE AWSFile.CBP_DDTransHistory_InsertDatesLoadedToFileLog (@DownloadStartDateTime datetime, @Date date)
AS
BEGIN
	
	SET NOCOUNT ON;

	INSERT INTO Archive_Light.dbo.CBP_DirectDebit_DatesLoadedToFileLog (AWSLoadDateStart, DateValueLoadedToFile)
	SELECT 
		@DownloadStartDateTime
		, @Date;

	/******************************************************************************
	--Create table for logging dates loaded to file

	CREATE TABLE Archive_Light.dbo.CBP_DirectDebit_DatesLoadedToFileLog (
		AWSLoadDateStart datetime NOT NULL
		, DateValueLoadedToFile date NOT NULL
		, CONSTRAINT PK_CBP_DirectDebit_DatesLoadedToFileLog PRIMARY KEY CLUSTERED (AWSLoadDateStart, DateValueLoadedToFile)
	);
	******************************************************************************/

END