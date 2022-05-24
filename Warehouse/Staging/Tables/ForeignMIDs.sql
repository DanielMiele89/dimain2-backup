CREATE TABLE [Staging].[ForeignMIDs] (
    [Narrative]       VARCHAR (50) NOT NULL,
    [LocationAddress] VARCHAR (50) NOT NULL,
    [LocationCountry] VARCHAR (3)  NOT NULL,
    [MCC]             VARCHAR (4)  NOT NULL,
    [Frequency]       INT          NULL,
    [TotalAmount]     MONEY        NULL,
    [ID]              INT          IDENTITY (1, 1) NOT NULL,
    PRIMARY KEY CLUSTERED ([ID] ASC)
);


GO
CREATE NONCLUSTERED INDEX [IX_ForeignMIDS_Narrative]
    ON [Staging].[ForeignMIDs]([Narrative] ASC, [MCC] ASC)
    INCLUDE([LocationAddress], [LocationCountry], [Frequency], [TotalAmount]);

