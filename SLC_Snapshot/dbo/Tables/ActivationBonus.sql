CREATE TABLE [dbo].[ActivationBonus] (
    [ID]                    INT        IDENTITY (1, 1) NOT FOR REPLICATION NOT NULL,
    [FanID]                 INT        NOT NULL,
    [ActivationBonusAmount] SMALLMONEY NOT NULL,
    [StartDate]             DATETIME   NOT NULL,
    [EndDate]               DATETIME   NULL,
    [Claimed]               BIT        NOT NULL,
    CONSTRAINT [PK_ActivationBonus] PRIMARY KEY CLUSTERED ([ID] ASC),
    CONSTRAINT [UNC_ActivationBonus] UNIQUE NONCLUSTERED ([FanID] ASC, [StartDate] ASC, [EndDate] ASC)
);

