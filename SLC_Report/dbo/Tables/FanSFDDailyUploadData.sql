CREATE TABLE [dbo].[FanSFDDailyUploadData] (
    [FanID]                 INT         NOT NULL,
    [ClubCashAvailable]     SMALLMONEY  NULL,
    [CustomerJourneyStatus] VARCHAR (3) NULL,
    [ClubCashPending]       SMALLMONEY  NULL,
    [WelcomeEmailCode]      CHAR (2)    NULL,
    [DateOfLastCard]        DATE        NULL,
    [CJS]                   CHAR (3)    NULL,
    [WeekNumber]            TINYINT     NULL,
    [IsDebit]               BIT         CONSTRAINT [DF_FanSFDDailyUploadData_IsDebit] DEFAULT ((0)) NOT NULL,
    [IsCredit]              BIT         CONSTRAINT [DF_FanSFDDailyUploadData_IsCredit] DEFAULT ((0)) NOT NULL,
    [RowNumber]             INT         NULL,
    [ActivatedDate]         DATETIME    NULL,
    [CompositeID]           BIGINT      NULL,
    [TotalEarning]          SMALLMONEY  CONSTRAINT [df_FanSFDDailyUploadData_TotalEarning] DEFAULT ((0)) NOT NULL,
    CONSTRAINT [PK_FanSFDDailyUploadData] PRIMARY KEY CLUSTERED ([FanID] ASC)
);

