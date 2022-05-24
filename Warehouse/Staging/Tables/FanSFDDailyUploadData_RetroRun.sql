CREATE TABLE [Staging].[FanSFDDailyUploadData_RetroRun] (
    [FanID]       INT         NULL,
    [WelcomeCode] VARCHAR (5) NULL,
    [NewCardDate] DATE        NULL
);


GO
DENY SELECT
    ON OBJECT::[Staging].[FanSFDDailyUploadData_RetroRun] TO [New_PIIRemoved]
    AS [dbo];

