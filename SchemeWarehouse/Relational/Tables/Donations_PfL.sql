CREATE TABLE [Relational].[Donations_PfL] (
    [Donations_PfL_ID]       INT        NOT NULL,
    [DonationFiles_PfL_ID]   INT        NOT NULL,
    [FanID]                  INT        NOT NULL,
    [Amount]                 SMALLMONEY NOT NULL,
    [PanID]                  INT        NOT NULL,
    [DonationsStatus_PfL_ID] INT        NULL,
    [AuthRef]                INT        NULL,
    [Excess]                 SMALLMONEY NULL,
    PRIMARY KEY CLUSTERED ([Donations_PfL_ID] ASC)
);


GO
CREATE NONCLUSTERED INDEX [IX_Donations_FanID]
    ON [Relational].[Donations_PfL]([FanID] ASC);

