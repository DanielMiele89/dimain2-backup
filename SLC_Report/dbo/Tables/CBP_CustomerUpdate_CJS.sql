CREATE TABLE [dbo].[CBP_CustomerUpdate_CJS] (
    [FanID]      INT      NOT NULL,
    [CJS]        CHAR (3) NULL,
    [WeekNumber] TINYINT  NULL,
    CONSTRAINT [PK_CBP_CustomerUpdate_CJS] PRIMARY KEY CLUSTERED ([FanID] ASC)
);

