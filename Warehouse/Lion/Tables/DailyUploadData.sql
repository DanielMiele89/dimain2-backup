CREATE TABLE [Lion].[DailyUploadData] (
    [FanID]      INT         NOT NULL,
    [CJS]        VARCHAR (3) NOT NULL,
    [WeekNumber] INT         NOT NULL,
    [IsCredit]   BIT         NOT NULL,
    [IsDebit]    BIT         NOT NULL,
    PRIMARY KEY CLUSTERED ([FanID] ASC)
);

