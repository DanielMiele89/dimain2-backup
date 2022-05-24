CREATE TABLE [Staging].[FanSFDDailyUploadData_PreviousDay] (
    [FanID]                 INT         NOT NULL,
    [ClubCashAvailable]     SMALLMONEY  NULL,
    [CustomerJourneyStatus] VARCHAR (3) NULL,
    [ClubCashPending]       SMALLMONEY  NULL,
    [WelcomeEmailCode]      CHAR (2)    NULL,
    [DateOfLastCard]        DATE        NULL,
    [CJS]                   CHAR (3)    NULL,
    [WeekNumber]            TINYINT     NULL,
    [IsDebit]               BIT         NOT NULL,
    [IsCredit]              BIT         NOT NULL,
    [RowNumber]             INT         NULL,
    [ActivatedDate]         DATETIME    NULL,
    [CompositeID]           BIGINT      NULL
);

