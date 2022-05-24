CREATE TABLE [dbo].[MI TeleTechCallStats] (
    [ID]                        INT        IDENTITY (1, 1) NOT NULL,
    [RunDate]                   DATE       NULL,
    [CallsOfferedYesterday]     INT        NOT NULL,
    [CallsHandledYesterday]     INT        NOT NULL,
    [CallsAbandonedYesterday]   INT        NOT NULL,
    [AverageTalkTimeYesterday]  FLOAT (53) NOT NULL,
    [CallsTransferredYesterday] INT        NOT NULL,
    CONSTRAINT [PK_MI_TeleTechCallStats] PRIMARY KEY CLUSTERED ([ID] ASC)
);

