CREATE TABLE [dbo].[FanSFDDailyUploadDataStaging] (
    [FanID]         INT      NOT NULL,
    [ActivatedDate] DATETIME NULL,
    CONSTRAINT [PK_FanSFDDailyUploadDataStaging] PRIMARY KEY CLUSTERED ([FanID] ASC)
);

