CREATE TABLE [Relational].[SFD_MOT3Wk1_PartnerSpend] (
    [ID]        INT          IDENTITY (1, 1) NOT NULL,
    [FanID]     INT          NOT NULL,
    [LastSpend] VARCHAR (50) NOT NULL,
    [Date]      DATE         NOT NULL,
    PRIMARY KEY CLUSTERED ([ID] ASC)
);


GO
CREATE NONCLUSTERED INDEX [SFD_MOT3Wk1_PartnerSpend_FanIDDate]
    ON [Relational].[SFD_MOT3Wk1_PartnerSpend]([FanID] ASC, [Date] ASC);

